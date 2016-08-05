class JdzeduSpider < BaseSpider

	def before_spider(url, doc)
		pages_doc = doc.css(".pn-bar")

		total_item_count = pages_doc.css("b").text.to_i
		set_item_count(total_item_count)

		total_page_count = pages_doc.css("ul li:last-child").text.scan(/\d+/)[1].to_i
		set_pages_info(1, total_page_count)
		
		return true
	end

	#新闻列表css选择
	def get_list_selector
		return ".div-right table[width='753'] tr a[target=_top]"
	end

	#获取下一页新闻列表的网址
	def get_next_url(base_url, next_page_number)
		next_page_url = URI.join(base_url, "?c=1&p=#{next_page_number}")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		title = detail_item.text

		# datetime_doc = detail_item.css("td:last-child")
		# datetime = DateTime.strptime(datetime_doc.text, '%Y年%m月%d日')
		publish_at = nil
		content_text = nil
		content_html = nil
		doc = get_html_document(url)
		if doc != nil
			b_doc = doc.css(".read-prop b")
			b_doc.each do |item|
				if item.text.include? "年"
					publish_at = DateTime.strptime(item.text.gsub(/\s+/, ""), '%Y年%m月%d日%H:%M:%S')
					break
				end
			end

			content_doc = doc.css(".read-content")
			content_text = content_doc.text.gsub(/\r/, "")
			content_text = content_text.gsub(/\n/, "")
			content_html = doc_to_html(content_doc, url)
		end

		#保存新闻数据
		return save_news(title, url, publish_at, content_text, content_html)
	end
end