class JaeduSpider < BaseSpider

	def init_charset
		@charset = "gbk"
	end

	def before_spider(url, doc)	
		pages_doc = doc.css("form[name=PageForm] b")
		total_item_count = pages_doc[0].text.to_i
		set_item_count(total_item_count)

		total_page_count = pages_doc.last.text.split("/").last.to_i
		set_pages_info(1, total_page_count)
		return true
	end

	#新闻列表css选择
	def get_list_selector
		return ".hj ul a"
	end

	#获取下一页新闻列表的网址
	def get_next_url(base_url, next_page_number)
		next_page_url = URI.join(base_url, "ShowClass.asp?ClassID=1&page=#{next_page_number}")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		title = detail_item.text
	
		doc = get_html_document(url)
		return true if doc.nil?

		info_doc = doc.css(".tdbg_all")
		
		datetime_doc = info_doc.css('font')
		publish_at = DateTime.strptime(datetime_doc.text, '%Y/%m/%d %H:%M:%S')

		# author_content = info_doc.css('.articleinfo_other a').text
		# author = '吉安教育网' if author.length == 0
		# author = get_author('吉安教育网', '吉安', author_content)
		# 录入（作者信息） 均为admin、mark之类，没有意义，因此同意采用‘吉安教育网’
		author = '吉安教育网'

		content_doc = doc.css(".ArticleBody")
		content_doc.css('table')[0].remove
		# content_text = content_doc.text.gsub(/^\s+/, '')
		# content_html = doc_to_html(content_doc, url)
		
		#保存新闻数据
		# return save_news(title, url, author, publish_at, content_text, content_html)
		return save_news(title, url, author, publish_at, content_doc)
	end
end