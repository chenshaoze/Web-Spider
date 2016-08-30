class YteduySpider < BaseSpider

	def init_charset
		@charset = "gbk"
	end

	def before_spider(url, doc)	
		pages_doc = doc.css(".huanye").last

		total_page_count = pages_doc.text.scan(/\d+/).first.to_i
		set_pages_info(1, total_page_count)
		return true
	end

	#新闻列表css选择
	def get_list_selector
		return ".list_list_con a"
	end

	#获取下一页新闻列表的网址
	def get_next_url(base_url, next_page_number)
		next_page_url = URI.join(base_url, "index_#{next_page_number-1}.htm")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		title = detail_item.text

		doc = get_html_document(url)
		return true if doc.nil?

		info_doc = doc.css(".Content_ExtField")
		publish_at = /\d{4}\W\d{1,2}\W\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}/.match(info_doc.text)
		if publish_at[0] != nil
			publish_at = DateTime.strptime(publish_at[0], '%Y-%m-%d %H:%M:%S')
		end

		author_content = info_doc.text[/来源：.*/]
		author_content['来源：'] = ''
		# author = '鹰潭教育信息网' if author.length == 0
		author = get_author('鹰潭教育信息网', '鹰潭', author_content)

		content_doc = doc.css("#_NewsContent")
		
		try_content_doc = content_doc.css('.TRS_Editor')
		content_doc = try_content_doc if try_content_doc.length != 0

		try_content_doc = content_doc.css('.TRS_PreAppend')
		content_doc = try_content_doc if try_content_doc.length != 0

		# content_html = doc_to_html(content_doc, url)
		# content_text = content_doc.text.gsub(/\s+/, "")

		
		# #保存新闻数据
		# return save_news(title, url, author, publish_at, content_text, content_html)
		return save_news(title, url, author, publish_at, content_doc)
	end
end