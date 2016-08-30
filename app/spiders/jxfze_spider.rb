class JxfzeSpider < BaseSpider

	def before_spider(url, doc)	
		pages_doc = doc.css("#pages")
		total_item_count = pages_doc.css("a.a1").first.text.chop.to_i
		set_item_count(total_item_count)

		total_page_count =pages_doc.css("a:not(.a1)").last.text.to_i
		set_pages_info(1, total_page_count)
		return true
	end

	#新闻列表css选择
	def get_list_selector
		sleep(5.seconds)
		return ".scy_lbsj-right-nr li"
	end

	#获取下一页新闻列表的网址
	def get_next_url(base_url, next_page_number)
		next_page_url = URI.join(base_url, "list-21-#{next_page_number}.html")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		title = detail_item.css("a").text

		datetime_doc = detail_item.css("span")
		publish_at = DateTime.strptime(datetime_doc.text, '%Y-%m-%d %H:%M:%S')

		doc = get_html_document(url)
		return true if doc.nil?

		info_doc = doc.css('#content_date_source')
		author_content = info_doc.text[/来源：[\u4e00-\u9fa5_a-zA-Z0-9_]*/]
		author_content['来源：'] = ''
		# author = '抚州教育网' if author.length == 0
		author = get_author('抚州教育网', '抚州', author_content)

		content_doc = doc.css(".TRS_Editor")
		# content_html = doc_to_html(content_doc, url)
		# content_text = content_doc.text
		
		# #保存新闻数据
		# return save_news(title, url, author, publish_at, content_text, content_html)
		return save_news(title, url, author, publish_at, content_doc)
	end
end