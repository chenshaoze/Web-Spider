# 南昌教育信息网的新闻抓取类
class NceduSpider < BaseSpider

	def init_charset
		@charset = "gbk"
	end

	def spider_news_list(url, doc)
		news_list = doc.css(".TABLE1")

		set_item_count(news_list.length)
		news_list.each do |item|
			spider_detail(url, item)
		end 
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		load_detail_page_success = true

		detail_page_content = get_html_document(url)
		load_detail_page_success = false if detail_page_content.nil?
				
		title = detail_item.css('a').text

		datetime = detail_item.css("div[align='right'] font")
		publish_at = DateTime.strptime(datetime.text, '[%Y-%m-%d]')
		
		content_text = nil
		content_html = nil
		if load_detail_page_success
			content_doc = detail_page_content.css('.newss')
			content_text = content_doc.text.strip
			content_html = doc_to_html(content_doc, url)
		end
		
		#保存新闻数据
		return save_news(title, url, publish_at, content_text, content_html)
	end

end
