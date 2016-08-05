# 国家教育资源公共服务平台的新闻抓取类
class JxeduSpider < BaseSpider

	def before_spider(url, doc)
		td_doc = doc.css("td[colspan='2']")
		pages_doc = td_doc.text.gsub(/\s+/m, ' ').strip.split(" ")

		page_info = pages_doc[0].scan(/\d+/)
		set_item_count(page_info[1].to_i)
		set_pages_info(page_info[2].to_i, page_info[0].to_i)
		return true
	end

	#新闻列表css选择
	def get_list_selector
		return "a[target=_blank]"
	end

	def get_next_url(base_url, next_page_number)
		next_page_url = URI.join(base_url, "index_#{next_page_number}.html")
		return next_page_url
	end

	#获取本地域名的新闻的详细信息
	def spider_localhost_detail(url, detail_item)
		doc = get_html_document(url)
		return true if doc.nil?

		#抓取标题
		title = doc.css('.title').text

		publish_at = nil
		#抓取时间
		datetime = doc.css('div[align=center]:has(.STYLE1)').text.gsub(/\s+/, "")
		datetime = /\d{4}\W\d{1,2}\W\d{1,2}\d{1,2}:\d{1,2}:\d{1,2}/.match(datetime)
		if datetime != nil
			publish_at = DateTime.strptime(datetime[0], '%Y-%m-%d%H:%M:%S')
		end

		#抓取内容
		content_doc = doc.css('td[id=NewsContent]')
		content_text = content_doc.text
		content_html = doc_to_html(content_doc, url)

		#保存新闻数据
		return save_news(title, url, publish_at, content_text, content_html)
	end

end