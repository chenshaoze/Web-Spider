class JjeSpider < BaseSpider

	def init_charset
		@charset = "gbk"
	end

	def before_spider(url, doc)
		pages_doc = doc.css("table.body td")
		item_count_doc = pages_doc.css("b")
		total_item_count = item_count_doc[0].text.to_i
		set_item_count(total_item_count)

		page_count_doc = pages_doc.css("strong")
		page_count_arr = page_count_doc.text.split("/")
		set_pages_info(page_count_arr[0].to_i, page_count_arr[1].to_i)
		return true
	end

	#新闻列表css选择
	def get_list_selector
		return ".txt14 table[cellpadding='2'] tr"
	end

	#获取下一页新闻列表的网址
	def get_next_url(base_url, next_page_number)
		next_page_url = URI.join(base_url, "?id=1&page=#{next_page_number}")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		title_doc = detail_item.css("a[target=_blank]")
		title = title_doc.text

		datetime_doc = detail_item.css("div[align=right]")
		datetime = datetime_doc.text.strip.split(" ")[1]
		publish_at = DateTime.strptime(datetime, '%Y-%m-%d')

		doc = get_html_document(url)
		return true if doc.nil?

		author_content = doc.css('div.txt14').text[/编辑\s*：[\u4e00-\u9fa5_a-zA-Z0-9_]*/]
		author_content[/编辑\s*：/] = ''
		# author = '九江教育网' if author.length == 0
		# 一般都为jje，因此凡是为jje的直接命名为‘九江教育网’
		if author_content == 'jje'
			author = '九江教育网'
		else
			author = get_author('九江教育网', '九江', author_content)
		end
		

		content_doc = doc.css("#Zoom")
		# content_html = doc_to_html(content_doc, url)
		# content_text = content_doc.text.gsub(/\r/, "")
		# content_text = content_text.gsub(/\n/, "")

		# #保存新闻数据
		# return save_news(title, url, author, publish_at, content_text, content_html)
		return save_news(title, url, author, publish_at, content_doc)
	end
end