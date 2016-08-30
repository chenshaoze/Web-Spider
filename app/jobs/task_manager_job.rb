# require 'sidekiq/api'
require 'tiny_tds' 

class TaskManagerJob < ActiveJob::Base
  queue_as :task_manage

  def perform(*args)
  	@wait_durance = 30.seconds
  	@source = args[0]
  	log(@source, 'push data begin')
  	# 打开sqlserver数据库连接
  	client = TinyTds::Client.new username: 'sa', password: '123456', host: '192.168.88.197', database: 'test'
  	# 一次取100条数据进行插入处理
  	limit = 100
  	# column和value的对应hash
  	columns_hash = { 
  									 ClassID: '1120',#预分配的ClassID
  									 FullTitle: nil, #title
  									 KeyWords: nil, #title
  									 Author: nil, #author
  									 Origin: nil, #author
  									 ArticleContent: nil, #html
  									 AddDate: nil, #publish_at
  									 PicUrl: nil, #pic_url
  									 IsPicNews: nil, #is_pic_news
  									 TitleFontColor: '0',
  									 TitleFontType: '0',
  									 Editor: '1',
  									 Hits: '0',
  									 InputUserID: '1',
  									 IsRecommend: '0',
  									 IsPopular: '0',
  									 IsTop: '0',
  									 IsEssential: '0',
  									 IsAudit: '2',
  									 IsComment: '0',
  									 IsDelete: '0',
  									 Audit: '1',
  									 AuditDate: Time.now.strftime('%Y-%m-%d %H:%M:%S')
  								} 
  	loop do
  		# 查询是否有需要入库的数据，凭证为sync字段为0
	  	news_need_sync = News.where(source: @source, sync: 0).take(limit)
	  	# 循环插入数据
		  news_need_sync.each do |row| 
		  	columns_hash[:FullTitle] = row.title
		  	columns_hash[:KeyWords]  = row.title
		  	columns_hash[:Author]    = row.author
		  	columns_hash[:Origin]    = row.author
		  	columns_hash[:ArticleContent] = row.html
		  	columns_hash[:AddDate]   = row.publish_at.strftime('%Y-%m-%d %H:%M:%S')
		  	columns_hash[:PicUrl]    = row.pic_url
		  	columns_hash[:IsPicNews] = row.is_pic_news.to_s

		  	insert_hash = get_insert_hash(client, columns_hash)
		  	# puts "INSERT INTO [Article] (#{insert_hash[:columns]}) VALUES(#{insert_hash[:values]})" 
		  	result = client.execute("INSERT INTO [Article] (#{insert_hash[:columns]}) VALUES(#{insert_hash[:values]})")
		  	result.insert
		  	# 记录已经同步
		  	row.sync = 1
		  	row.save
		  end 
		  break if news_need_sync.count < limit
		end
		# 关闭sqlserver数据库连接
		client.close
		log(@source, 'push data end')
  end

  def get_insert_hash(client, columns_hash)
  	columns_str = ''
  	values_str = ''
  	columns_hash.each do |key, value|
  		columns_str = columns_str + key.to_s + ','
  		values_str = + values_str + "'" + client.escape(value) + "',"
  	end
  	return {
  		# 删除最后一个逗号
  		columns: columns_str[0...-1],
  		values: values_str[0...-1]
  	}
  end

  #打印日志
	def log(*args)
		content = "#{DateTime.now.to_s}"
		args.each do |arg|
			content = content + " " + arg
		end
		content = content + "\n"
		printf content
	end

  rescue_from(StandardError) do |exception|
    puts "task_manage rescue: #{exception}"
    TaskManagerJob.set(wait: @wait_durance).perform_later(@source)
  end
end
