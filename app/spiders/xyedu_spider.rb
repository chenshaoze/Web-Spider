class XyeduSpider < BaseSpider

	def before_spider(url, doc)	
		pages_doc = doc.css(".yeanniu.pager")
		total_page_count = pages_doc.text.scan(/\d+/)[0]
		set_pages_info(1, total_page_count.to_i)
		return true
	end

	#新闻列表css选择
	def get_list_selector
		return "#all .box-content li"
	end

	#获取下一页新闻列表的网址
	def get_next_url(base_url, next_page_number)
		#新余网站的的页面逻辑为，第一页为index.html，第二页为index_1.html
		next_page_url = URI.join(base_url, "index_#{next_page_number - 1}.html")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		title_doc = detail_item.css("a[target=_blank]")
		title = title_doc.text

		datetime_doc = detail_item.css("p")
		publish_at = DateTime.strptime(datetime_doc.text, '%Y/%m/%d')
		
		content_text = nil
		content_html = nil
		doc = get_html_document(url)
		if doc != nil
			content_doc = doc.css("#text")
			content_text = content_doc.text.gsub(/\r/, "")
			content_text = content_text.gsub(/\n/, "")
			content_html = doc_to_html(content_doc, url)
		end
		
		#保存新闻数据
		return save_news(title, url, publish_at, content_text, content_html)
	end
end