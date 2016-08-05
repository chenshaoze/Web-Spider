class JxycjySpider < BaseSpider

	def init_charset
		@charset = "gbk"
	end

	def before_spider(url, doc)	
		total_page_count =doc.css("#pageLast").text.to_i
		set_pages_info(1, total_page_count)
		return true
	end

	#新闻列表css选择
	def get_list_selector
		return ".h_news li"
	end

	#获取下一页新闻列表的网址
	def get_next_url(base_url, next_page_number)
		next_page_url = URI.join(base_url, "/web/class/0/a5-#{(next_page_number-1)*22}-981")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		title = detail_item.css("a").text

		datetime_doc = detail_item.css("span")
		publish_at = DateTime.strptime(datetime_doc.text, '%Y-%m-%d %H:%M:%S')

		content_text = nil
		content_html = nil
		doc = get_html_document(url)
		if doc != nil
			content_doc = doc.css(".display_wen")
			content_doc.search("style").remove
			content_text = content_doc.text.gsub(/\s+/, "")
			# content_text = content_text.gsub(/<!--.*-->/, "")
			content_html = doc_to_html(content_doc, url)
		end
		
		#保存新闻数据
		return save_news(title, url, publish_at, content_text, content_html)
	end
end