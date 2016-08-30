class SrjywSpider < BaseSpider

	def init_charset
		@charset = "gbk"
	end

	def before_spider(url, doc)	
		pages_doc = doc.css(".showpage")
		total_item_count = pages_doc.css("b")[0].text.to_i
		set_item_count(total_item_count)

		input_doc = pages_doc.css("input")
		total_page_count = input_doc.attr("onkeypress").to_s.scan(/\d+/)[0].to_i
		set_pages_info(1, total_page_count)
		return true
	end

	#新闻列表css选择
	def get_list_selector
		return "a.listA"
	end

	#获取下一页新闻列表的网址
	def get_next_url(base_url, next_page_number)
		next_page_url = URI.join(base_url, "/Article/ShowClass.asp?ClassID=1&page=#{next_page_number}")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		sleep(5.seconds)
		title = detail_item.text

		doc = get_html_document(url)
		return true if doc.nil?

		info_doc = doc.css(".pagetitle2")
		datetime = info_doc.text.scan(/\d+\/\d+\/\d+/)[0]
		publish_at = DateTime.strptime(datetime, '%Y/%m/%d')

		# author_content = info_doc.text[/作者：[\u4e00-\u9fa5_a-zA-Z0-9_]*/]
		# author_content['作者：'] = ''
		# # author = '上饶教育网' if author.length == 0
		# author = get_author('上饶教育网', '上饶', author_content)
		# 所有新闻都为“作者：佚名    信息来源：本站原创”，因此作者信息统一采用‘上饶教育网’
		author = '上饶教育网'

		content_doc = doc.css("#fontzoom")
		# content_html = doc_to_html(content_doc, url)
		# content_text = content_doc.text

		
		# #保存新闻数据
		# return save_news(title, url, author, publish_at, content_text, content_html)
		return save_news(title, url, author, publish_at, content_doc)
	end
end