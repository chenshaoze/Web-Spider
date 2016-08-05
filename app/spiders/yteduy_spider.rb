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

		publish_at = nil
		content_text = nil
		content_html = nil
		doc = get_html_document(url)
		if doc != nil
			datetime_doc = doc.css(".Content_ExtField")
			publish_at = /\d{4}\W\d{1,2}\W\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}/.match(datetime_doc.text)
			if publish_at[0] != nil
				publish_at = DateTime.strptime(publish_at[0], '%Y-%m-%d %H:%M:%S')
			end

			content_doc = doc.css("#_NewsContent")
			content_text = content_doc.text.gsub(/\s+/, "")
			content_html = doc_to_html(content_doc, url)
		end
		
		#保存新闻数据
		return save_news(title, url, publish_at, content_text, content_html)
	end
end