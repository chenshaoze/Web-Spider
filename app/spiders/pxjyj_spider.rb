class PxjyjSpider < BaseSpider

	def init_charset
		@charset = "gbk"
	end

	def before_spider(url, doc)

		pages_doc = doc.css("#pageLast")
		set_pages_info(1, pages_doc.text.to_i)
		return true
	end

	#新闻列表css选择
	def get_list_selector
		return ".co li"
	end

	#获取下一页新闻列表的网址
	def get_next_url(base_url, next_page_number)
		next_page_url = URI.join(base_url, "/web/class/0/a7-#{(@current_page_number-1)*16}-136")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		title_doc = detail_item.css("a")
		title = title_doc.text

		datetime_doc = detail_item.css("i")
		publish_at = DateTime.strptime(datetime_doc.text, '%Y-%m-%d %H:%M:%S')	

		doc = get_html_document(url)
		return true if doc.nil?

		info_doc = doc.css('.p3')
		info_doc = doc.css('.content_time_l') if info_doc.length == 0
		author_content = info_doc.text[/来源：[\u4e00-\u9fa5_a-zA-Z0-9_]*/]
		author_content['来源：'] = ''
		# author = '萍乡市教育局' if author.length == 0
		author = get_author('萍乡市教育局', '萍乡', author_content)

		content_doc = doc.css(".p5")
		content_doc = doc.css('.content_content') if content_doc.length == 0
		# content_html = doc_to_html(content_doc, url)	
		# content_text = content_doc.text		
	
		# #保存新闻数据
		# return save_news(title, url, author, publish_at, content_text, content_html)
		return save_news(title, url, author, publish_at, content_doc)
	end
end