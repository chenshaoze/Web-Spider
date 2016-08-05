
# 国家教育资源公共服务平台的新闻抓取类
class EduyunSpider < BaseSpider
	@@charset = "utf-8"
  def before_spider(url, doc) 
  	#获取首条新闻
  	#eduyun的首条新闻较为特殊，每个分页都有一条相同的置顶的新闻。
		#但也并非绝对，有偶尔个别页面的置顶新闻会略有不同。

		#获取新闻条目总数
		div = doc.css('.list .list_left ul li.list_li_2 div')
		info_line = div.text.split(/[.\n]+/)[1]

		page_info = info_line.scan(/\d+/)
		set_item_count(page_info[0].to_i)
		set_pages_info(page_info[1].to_i, page_info[2].to_i)

		# total_item_count = /\d+/.match(div.text)[0]
		# set_item_count(total_item_count.to_i)
		
		#获取首条新闻的内容
		firstNews = doc.css('.list .list_left ul li.list_li_1')
		spider_detail(url, firstNews)

		return true
	end

	#新闻列表css选择
	def get_list_selector
		return ".list .list_left ul li:not(.list_li_1):not(.list_li_2)"
	end

	def get_next_url(base_url, next_page_number)
		#返回下一页新闻列表的链接
		# next_url = doc.css('.list .list_left ul li.list_li_2 a')[2].attr('href')
		# return next_url != nil ? URI.join(url, next_url).to_s : nil
		next_page_url = URI.join(base_url, "index_#{next_page_number}.html")
		return next_page_url
	end

	#获取非本地域名的新闻的部分详细信息
	def spider_other_domain_detail(url, detail_item)
		begin
			texts = detail_item.text.gsub(/\s+/m, ' ').strip.split(" ")
			publish_at = DateTime.strptime(texts[texts.length - 1], '%Y/%m/%d')
			# return false if !validate_datetime(publish_at)
			return save_news(detail_item.css('a').text, url, publish_at, nil, nil)
		rescue Exception => e
			log(e.message)
		end
		return true
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		detail = get_html_document(url)
		return true if detail == nil

		#获取新闻标题
		title = detail.css('.list .list_left ul li.page_li_1')
		title = title.text
		#新闻副标题
		sec_title = detail.css('.list .list_left ul li.page_li_11')
		title = title + sec_title.text

		#获取新闻发布时间
		publish_at = nil
		datetime = detail.css('.list .list_left ul li dd')
		if datetime.length > 2
			datetime = /\d{4}\W\d{1,2}\W\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}/.match(datetime[1].text)
			if datetime[0] != nil
				publish_at = DateTime.strptime(datetime[0], '%Y-%m-%d %H:%M:%S')
				#如果新闻发布时间早于数据库中记录的最新的一条新闻的发布时间，则停止抓取动作
				return false if !validate_datetime(publish_at)
			end
		end

		#图文类型和视频文字类型基本不会同时出现

		#获取新闻的内容(图文类型)
		content_doc = detail.css('.list .list_left ul li.page_li_2')
		content_text = nil
		content_html = nil
		if content_doc.length > 0
			content_text = content_doc.text
			content_html = doc_to_html(content_doc, url)
		end

		#获取新闻内容（视频文字类型）
		content_doc =  detail.css('.list .list_left ul li.page_li_n')
		if content_doc.length > 0
			content_html = content_doc.to_s
			content_text = content_doc.text
		end
		
		#保存新闻数据
		return save_news(title, url, publish_at, content_text, content_html)
	end

end