class JxgzeduSpider < BaseSpider

	def init_charset
		@charset = "gbk"
	end

	def before_spider(url, doc)	
		pages_doc = doc.css(".pager a").last
		total_page_count = pages_doc.attr("href").scan(/\d+/).last.to_i
		set_pages_info(1, total_page_count)
		return true
	end

	#新闻列表css选择
	def get_list_selector
		sleep(5.seconds)
		return ".newslist li"
	end

	#获取下一页新闻列表的网址
	def get_next_url(base_url, next_page_number)
		next_page_url = URI.join(base_url, "/article/index.asp?C_ID=8&p=#{next_page_number}")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		title = detail_item.css("a").text

		doc = get_html_document(url)
		return true if doc.nil?

		publish_at = nil
		info_doc = doc.css(".info")
		datetime = /\d{4}\W\d{1,2}\W\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}/.match(info_doc.text)
		if datetime[0] != nil
			publish_at = DateTime.strptime(datetime[0], '%Y/%m/%d %H:%M:%S')
		end

		author_content = info_doc.text[/作者：[\u4e00-\u9fa5_a-zA-Z0-9_]*/]
		author_content['作者：'] = ''
		# author = '赣州教育网' if author.length == 0
		author = get_author('赣州教育网', '赣州', author_content)

		content_doc = doc.css(".TRS_Editor")
		# content_text = content_doc.text.gsub(/\s+/, "")
		# content_html = doc_to_html(content_doc, url)
		
		# #保存新闻数据
		# return save_news(title, url, author, publish_at, content_text, content_html)
		return save_news(title, url, author, publish_at, content_doc)
	end
end