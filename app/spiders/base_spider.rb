require 'nokogiri'
require 'open-uri'

#新闻获取爬虫基类
#子类的命名采用域名+Spider的驼峰命名法。
#如：国家教育公共资源服务平台_教育新闻	http://news.eduyun.cn/ns/njiaoyuxianwen/
#则其爬虫类的命名为EduyunSpider
class BaseSpider
	#初始化方法
	def initialize(url, source)
		#本站域名
		@domain = URI.parse(url).host.downcase
		@source = source

		@datetime_publish = proc_task 

		#用于记录当前完成新闻的解析数量
		@current_item_count = 0
		#用于记录新闻总数
		@total_item_count = 0

		#初始化当前页数
		@current_page_number = 0
		#初始化总页数
		@total_page_count = 0

		# 是否有新的记录
		@new_record_arrived = false

		log(@source, 'start')
		log(@source, '预设截止时间：', @datetime_publish.to_s)
		#进行抓取工作
		call(url)
		# 如果有新的数据，则将数据转至电教馆新闻库
		TaskManagerJob.perform_later(source) if @new_record_arrived
		log(@source, 'end')
	end

	#通过task表记录的情况，判断获取新闻的时间截止点
	#如果返回nil，则说明没有完整记录过该站的新闻，即程序将该站的新闻全部抓取
	def proc_task()
		#获取已记录的最新的新闻发布时间
		@task = Task.where(source: @source).first

		#获取该类新闻的最近的发布时间，用户对比是否有新闻更新
		#引入task对象是为了容错，只有在抓取工作完成时才会更新task对象中的时间
		#如果程序意外终止，则task时间不会被更新，那么上次终止任务所录入的数据将会被清除，从而重新进行录入
		#这样可保证逻辑的正确性
		#最多仅获取最近两个月的新闻
		datetime_publish = DateTime.now - 2.month
		# datetime_publish = nil
		if @task.nil?
			#初始化任务时把噪声数据都删掉。
			#**但这样会有一定的危险性，因此在正式上线时需要考虑是否添加该功能**
			News.delete_all(["source = ?", @source])
			@task = Task.new
			@task.source = @source
			@task.save
		else
			#清理数据
			#该数据有可能是未完成的任务所添加的，为了保持逻辑的准确性，须先清理数据
			if @task.last_item_datetime.nil?
				News.delete_all(["source = ?", @source])
			else
				#如果最后一次更新的时间在两个月以内，则以最后一次更新的时间为准
				datetime_publish = @task.last_item_datetime if @task.last_item_datetime > datetime_publish
				News.delete_all(["source = ? AND publish_at > ?", @source, datetime_publish])
			end
		end
		return datetime_publish
	end

	#抓取入口方法
	#各个子类需在重载该方法的同时，调用该方法
	def call(url)
		#初始化字符集，默认utf-8
		#如有不同的字符集，则子类自行重写该方法
		init_charset()

		url = modify_url(url)

		#获取主url的html内容，如果失败则立即停止抓取过程
		@doc = get_html_document(url)
		return if @doc.nil?

		#准备工作失败则立即停止抓取
		return if !before_spider(url, @doc)

		#循环读取每一个分页的新闻
		next_page_url = url
		loop do 
			whether_next = spider_news_list(url, @doc)
			#如果不再进行新闻抓取，则立刻停止抓取工作
			break if !whether_next

			#显示进度
			show_percent()

			# 获取下一页新闻列表
			@current_page_number = @current_page_number + 1	
			#如果超出总页数，则停止抓取
			break if @current_page_number > @total_page_count
			
			#如果下一页的地址为空, 则结束抓取工作
			next_page_url = get_next_url(url, @current_page_number)
			break if next_page_url.nil?
			#获取失败则立即停止抓取工作
			@doc = get_html_document(next_page_url)
			return if @doc.nil?
		end

		#存储最新一条新闻的发布时间，作为下一次抓取新闻的依据
		@task.last_item_datetime = News.where(source: @source).maximum("publish_at")
		@task.save
	end
	
	#获取新闻内容
	#根据新闻内容页的网址判断是否为本站页面
	#如果为本站页面则按照本站页面的规则进行处理
	#反之则按照其他规则进行处理
	def spider_detail(url, detail_item)
		begin
			#增加已获取新闻的条目数
			@current_item_count = @current_item_count + 1

			detailUri = get_detail_url(url, detail_item)
			#判断详细页面是否为本网站的页面
			if @domain.eql?(detailUri.host.downcase)
				return spider_localhost_detail(detailUri.to_s, detail_item)
			else
				return spider_other_domain_detail(detailUri.to_s, detail_item)
			end
		rescue Exception => e
			log(e.message)
		end
		return true
	end

	#获取新闻详细页面的链接
	def get_detail_url(url, item)
		if item.class.name == "Nokogiri::XML::NodeSet" || item.name != 'a'
			item = item.css('a')
		end
		ref = item.attr('href')
		URI.join(url, ref)
	end
	
	#************工具方法**************

	#获取序列化的html doc对象
	#如果返回值为nil，则说明获取失败
	def get_html_document(url)
		result = nil
		begin
			result = Nokogiri::HTML(open(url), nil, @charset)
		rescue Exception => e
			log(url.to_s, e.message)
		end
		return result
	end

	#通过css选择器筛选html doc对象
	# def css_selector(doc, css)
	# 	return doc.css(css)
	# end

	#设置新闻条目总数
	#配合进度打印
	def set_item_count(total_count)
		@total_item_count = total_count
		log(@source, "共 #{@total_item_count}条记录")
	end

	#设置页数信息
	def set_pages_info(current_page_number, total_page_count)
		@current_page_number = current_page_number
		@total_page_count = total_page_count
		log(@source, "共 #{@total_page_count}页")
	end

	#打印进度
	def show_percent()
		if @total_item_count > 0
			log(@source, "#{@current_item_count}/#{@total_item_count}", "#{format('%.2f', @current_item_count.to_f / @total_item_count.to_f * 100)}%")
		elsif @total_page_count > 0
			log(@source, "#{@current_page_number}/#{@total_page_count}", "#{format('%.2f', @current_page_number.to_f / @total_page_count.to_f * 100)}%")
		end
	end

	#判断时间是否合法
	#当新闻的时间大于本次录入数据前数据库中最新的一条记录的新闻发布时间，则即为合法
	def validate_datetime(datetime, title = '')
		if @datetime_publish.nil?
			return true
		end

		if datetime < @datetime_publish
			log(@datetime_publish.to_s, datetime.to_s)
			return false
		elsif datetime == @datetime_publish
				#有些网站时间发布并不准确，有时仅包含年月日，并没有时分秒
				#这时需要增加当时间相等的判断逻辑
				#查找是否有相同的title的记录
				news = News.where("source=? AND title=?", @source, title).first
				if news.nil?
					return true
				else
					log("数据",news.title, datetime.to_s, "已存在！")
					return false
				end
		end
		return true
	end

	# 整理作者信息
	# default：默认作者信息如“南昌市教育信息网”
	# pre：头信息，如“南昌”、“南昌教育”，该信息会适时增加在content前面
	# content：从页面解析的作者或来源信息
	def get_author(default, pre, content)
		# 如果content为空或者为空白，则以默认信息作为作者信息
		return default if content.nil? || content.length == 0
		# 如果content包含pre头信息，则直接以content的内容作为作者信息
		return trim(content) if content.include? pre
		# 如果content没有包含pre头信息，则以pre+content
		# 应对content中只包含“市考试院”、“局新闻中心”等
		return pre + trim(content)
	end

	# 删除节点中的所有属性
	def removeAllAttr(node)
		node.keys.each do |attribute|
    	node.delete attribute
  	end
	end

	# 从doc中提取html,并判断新闻中是否包含图片
	def get_content_info(doc, url)
		# 删除不需要的节点
		doc.xpath('//comment()').remove
		doc.css('script').remove
		doc.css('style').remove

		# 删除所有p标签中的所有属性
		p_tags = doc.css('p')
		p_tags.each do |p|
			removeAllAttr(p)
		end

		# 删除所有span标签中的所有属性
		span_tags = doc.css('span')
		span_tags.each do |span|
			removeAllAttr(span)
		end

		# 删除所有div标签中的所有属性
		div_tags = doc.css('div')
		div_tags.each do |div|
			removeAllAttr(div)
		end

		# 是否包含图片
		has_image = 0
		# 如果包含，则记录第一张图片的url地址
		first_image_url = ''
		# 将img标签中的相对地址换成绝对地址，并添加预设的样式
		images = doc.css('img')
		images.each do |image|
			begin
				original_src = URI::escape(image.attr('src').to_s)
				absolute_src = URI.join(url, original_src).to_s
				removeAllAttr(image)
				image['src'] = absolute_src
				image['style'] = 'TEXT-ALIGN: center; MARGIN: 0px auto; DISPLAY: block'
				image['border'] = '0'
				image['width'] = '450'

				first_image_url = absolute_src if has_image == 0
				has_image = 1
			rescue Exception => e
				log(e.message)
			end
		end
		return { 
						 html: trim(doc.children.to_s).gsub(/&#160;/, ''),
						 is_pic_news: has_image,
						 pic_url: first_image_url
						}
	end

	#保存新闻，入库
	def save_news(title, url, author, publish_at, content_doc)
		# 如果新闻发布时间早于数据库中记录的最新的一条新闻的发布时间，则停止抓取动作
		return false if !validate_datetime(publish_at, title)
		# 如果没有内容，则不进行入库操作
		return true if content_doc.length == 0

		content_hash = get_content_info(content_doc, url)

		@new_record_arrived = true
		news = News.new
		news.source = @source
		news.sync = 0
		news.url = url
		news.title = trim(title)
		news.author = author
		news.publish_at = publish_at
		news.html = content_hash[:html]
		news.is_pic_news = content_hash[:is_pic_news]
		news.pic_url = content_hash[:pic_url]
		return news.save
	end

	# 去除字符串前后的空白字符
	def trim(str)
		# str.gsub(/^(\s|\u00A0)+|(\s|\u00A0)+$/, '')
		str.gsub(/^\s+|\s+$/, '')
	end

	#打印日志
	def log(*args)
		content = "#{DateTime.now.to_s}"
		args.each do |arg|
			content = content + " " + arg
		end
		content = content + "\n"
		printf content
	end

	#************抽象方法**************
	#初始化页面的字符集，默认为utf-8
	def init_charset
		@charset = "utf-8"
	end

	def modify_url(url)
		return url
	end

	#抓取新闻列表前所需的动作
	#如获取新闻总数、抓取特殊新闻等
	def before_spider(url, doc)
		return true
	end

	#抓取新闻列表
	#方法返回值为下一页新闻列表的url，如果为nil则说明抓取工作结束
	#**提供默认实现，如果有特殊情况则覆盖此方法，功能在具体的子类中实现**
	def spider_news_list(url, doc)
		#是否继续抓取标识
		whether_next = false
		#获取预设的css选择器
		css_selector = get_list_selector()
		if css_selector != nil
			#获取新闻列表
			news_list = doc.css(css_selector)
			#通过新闻列表循环获取新闻内容
			news_list.each do |item|
				#如果抓取详细信息的过程中，出现致命错误或无有效的新闻抓取时，
				#立即停止抓取工作
				#发现有些网站第一条记录是错乱的，因此不能仅通过一条记录进行判断是否退出
				# return false if !spider_detail(url, item)
				whether_next = spider_detail(url, item)
			end	
		end

		return whether_next
		# return true
	end

	#新闻列表css选择
	def get_list_selector
		return nil
	end

	#获取下一页新闻列表的网址
	#如果返回nil，则停止抓取活动
	def get_next_url(base_url, next_page_number)
		return nil
	end

	#获取本地域名的新闻的详细信息
	#**功能在具体的子类中实现**
	def spider_localhost_detail(url, detail_item)
		log("super localhost domain detail:", url)
		return true
	end

	#获取非本地域名的新闻的部分详细信息
	#**功能在具体的子类中实现**
	def spider_other_domain_detail(url, detail_item)
		log("super other domain detail:", url)
		return true
	end
end