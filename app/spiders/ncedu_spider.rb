# 南昌教育信息网的新闻抓取类
class NceduSpider < BaseSpider

	def init_charset
		@charset = "gbk"
	end

	def modify_url(url)
		new_url = URI.join(url, Time.now.year.to_s + 'nzyxw/')
		return new_url
	end

	def before_spider(url, doc)
		pages_doc = doc.css("form[name='pageForm']")
		# pages_doc.children.remove
		pages_doc.css('select').remove
		page_count_arr = pages_doc.text.scan(/\d+/)

		set_item_count(page_count_arr[0].to_i)
		set_pages_info(page_count_arr[2].to_i, page_count_arr[1].to_i)
		return true
	end

	#新闻列表css选择
	def get_list_selector
		return "a[title='$article.name']"
	end

	def get_next_url(base_url, next_page_number)
		next_page_url = URI.join(base_url, "index#{next_page_number-1}.htm")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)

		doc = get_html_document(url)
		return true if doc.nil?
				
		title = detail_item.text

		info_doc = doc.css("td[bgcolor='fff6d3']")

		publish_at = DateTime.strptime(info_doc.text[/\[.+\]/], '[%Y-%m-%d]')

		author_content = info_doc.css('strong').text
		# author = '南昌教育信息网' if author.length == 0
		author = get_author('南昌教育信息网', '南昌', author_content)

		content_doc = doc.css('.newss')
		# content_html = doc_to_html(content_doc, url)
		# content_text = content_doc.text.strip

		# #保存新闻数据
		# return save_news(title, url, author, publish_at, content_text, content_html)
		return save_news(title, url, author, publish_at, content_doc)
	end

end
