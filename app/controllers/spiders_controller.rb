require 'sidekiq/api'
class SpidersController < ApplicationController
	def index
		@spiders = Spider.all
	end

	def new
		@spider = Spider.new()
	end

	def create
		@spider = Spider.new(spider_params)
		@spider.source = Digest::MD5.hexdigest @spider.url
		@spider.status = 0
		@spider.save
		redirect_to spiders_path
	end

	def edit
		@spider = Spider.find(params[:id])
	end

	def update
		@spider = Spider.find(params[:id])
		@spider.update(spider_params)
		redirect_to spiders_path
	end

	def destroy
		spider = Spider.find(params[:id])
		spider.destroy
		redirect_to spiders_path
	end

	def start
		sleep(0.5.seconds)
		@spider = Spider.find(params[:id]) 
		@spider.status = (@spider.status - 1).abs
		if @spider.save && whether_start_job(@spider)
			# 启动任务
			SpiderJob.perform_later(@spider.url, @spider.source)
		end
	end

	# def task
	# 	# @task_state = params[:state].to_i
	# 	# queue = Sidekiq::Queue.new("task_manage")
	# 	# puts "task_manage queue size #{queue.size}"
	# 	# if @task_state > 0 && queue.size == 0
	# 		TaskManagerJob.perform_later
	# 	# end

	# 	queue = Sidekiq::Queue.new(:task_manage)
	# 	puts "task_manage queue.size = #{queue.size}"

	# 	workers = Sidekiq::Workers.new
	# 	puts workers.size 
	# 	workers.each do |process_id, thread_id, work|
	# 		puts work.class
	# 	end

	# 	# Sidekiq.redis do |r| 
 #  # # r.srem "queues", "app_queue"
 #  # # r.del  "queue:app_queue"
 #  # 		puts r
	# 	# end

	# 	# queue = Sidekiq::Queue.new
	# 	# puts "default queue size #{queue.size}"
 #  #   puts queue.size
	# 	# respond_to do |format|
	# 	# 	format.js
	# 	# end
	# end

	private 
	def spider_params
		params.require(:spider).permit!
	end

	def whether_start_job(spider)
		#清理ScheduledSet和Queue队列
		#将于spider.source相同的任务都删除掉
		puts "scheduledSet"
		scheduled = Sidekiq::ScheduledSet.new
		scheduled.each do |job|
			job_hash = job.args[0]
			if job_hash['arguments'][1] == spider.source
				job.delete
				puts "delete #{spider.source}"
			end
		end

    puts "queue"
    queue = Sidekiq::Queue.new
		queue.each do |job|
			job_hash = job.args[0]
			if job_hash['arguments'][1] == spider.source
				job.delete
				puts "delete #{spider.source}"
			end
		end

		#关闭状态，则不再启动任务
		if spider.status == 0
			return false
		end

		#如果是开启状态，且有与spider.source相同的任务在执行
		#则无需再启动任务
		puts "workers"
		workers = Sidekiq::Workers.new
		workers.each do |process_id, thread_id, work|
			if work['payload']['args'][0]['arguments'][1] == spider.source
				return false
			end
		end

		#排除万难，启动任务
		return true
	end
end
