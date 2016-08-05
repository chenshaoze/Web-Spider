require 'uri/http'
class SpiderJob < ActiveJob::Base
  queue_as :default
  def perform(*args)
    @wait_durance = 30.seconds

    @url = args[0]
    @source = args[1]

    puts "#{@url} start"
    
    if spider_running
    	#获取主域名 args[0]约定为需要抓取信息的url地址
    	domain =URI(@url).host.match(/\w+(?=\.(com|edu.cn|gov.cn|cn|net|org|biz|info|cc|tv))/)[0].to_s.capitalize
    	#通过主域名获取类名，爬虫类的命名约定采用域名+Spider的驼峰命名法
    	class_name = "#{domain}Spider"
    	#反射实例化类
    	class_name.constantize.new(@url, @source)	

      if spider_running
        SpiderJob.set(wait: @wait_durance).perform_later(@url, @source)
        puts "job will be scheduled!"
      end
    end

    puts "#{@url} end"
	end

  def spider_running
    spider = Spider.where(source: @source).first
    if spider == nil || spider.status == 0
      return false
    end
    return true
  end

	rescue_from(StandardError) do |exception|
    puts "rescue_from #{exception}"
    if spider_running
      puts "job will be scheduled!"
      SpiderJob.set(wait: @wait_durance).perform_later(@url, @source)
    end
  end
  
end
