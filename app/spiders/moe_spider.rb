class MoeSpider < BaseSpider

	def before_spider(url, doc)	
		pages_info = doc.css(".scy_tylb_fy-nr ul li").text.scan(/\d+/)
		total_item_count = pages_info[0].to_i
		set_item_count(total_item_count)

		set_pages_info(1, (total_item_count/20)+(total_item_count%20))
		return true
	end

	#新闻列表css选择
	def get_list_selector
		return ".scy_tylb-nr li"
	end

	#获取下一页新闻列表的网址
	def get_next_url(base_url, next_page_number)
		#新余网站的的页面逻辑为，第一页为index.html，第二页为index_1.html
		next_page_url = URI.join(base_url, "/was5/web/search?page=#{next_page_number}&channelid=282726&searchword=chnlid%3D2147438998")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		title = detail_item.css("a").text

		datetime_doc = detail_item.css("span")
		publish_at = DateTime.strptime(datetime_doc.text, '%Y-%m-%d')

		doc = get_html_document(url)
		return true if doc.nil?

		content_doc = doc.css("#content_body")
		info_doc = content_doc.css("#content_date_source")
		author = info_doc.text[/来源：[\u4e00-\u9fa5_a-zA-Z0-9_]*/]
		author['来源：'] = ''
		author = '教育部' if author.length == 0
		#清理无用信息
		info_doc.remove
		content_doc.css("#moeCode").remove
		content_doc.css(".moe_wcode").remove
		content_doc.css("#content_editor").remove
		content_doc.css("#content_page_num").remove
		content_doc.search("dl").remove
		
		# content_html = doc_to_html(content_doc, url)
		# content_text = content_doc.text.gsub(/^\s+/, " ")
		
		# #保存新闻数据
		# return save_news(title, url, author, publish_at, content_text, content_html)
		return save_news(title, url, author, publish_at, content_doc)
	end
end