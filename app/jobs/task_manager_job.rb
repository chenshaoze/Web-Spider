require 'sidekiq/api'
class TaskManagerJob < ActiveJob::Base
  queue_as :task_manage

  def perform(*args)
    # Do something later
    puts "My life Aiur!"
    queue = Sidekiq::Queue.new
    r = Sidekiq::ScheduledSet.new
    workers = Sidekiq::Workers.new
    
    total_jobs = 0
    loop do
    	puts "***********start**************"
    	
    	queue_size = queue.size
			puts "queue:#{queue.name}  queue.size = #{queue_size}"
			# queue.each do |job|
			# 		puts job.args[0]
			# 	end

			
			r_size = r.size
			puts "ScheduledSet.size = #{r_size}"
			# r.each do |job|
			# 		puts job.args[0]
			# 	end
			
			workers_size = workers.size
			puts "workers.size = #{workers_size}" 
			# workers.each do |process_id, thread_id, work|
			# 	puts work
			# end
			stats = Sidekiq::Stats.new

			puts "processed #{stats.processed}"
			puts "failed #{stats.failed}"
			# puts stats.queues # => { "default" => 1001, "email" => 50 }

			# temp_total_jobs = queue_size + r_size + workers_size
			# if total_jobs < temp_total_jobs
			# 	# puts "\n!!something wrong!!\n"
			# 	total_jobs = queue.size + r.size + workers.size
			# 	puts "current total_jobs = #{total_jobs}"
			# 	# puts "queue"
			# 	# queue.each do |job|
			# 	# 	puts job.args[0]
			# 	# end

			# 	# puts "scheduledset"
			# 	# r.each do |job|
			# 	# 	puts job.args[0]
			# 	# end

			# 	# puts "workers"
			# 	# workers.each do |process_id, thread_id, work|
			# 	# 	puts work
			# 	# end
			# end
			puts "***********sleep**************"
			sleep(5.seconds)
		end
  end

  rescue_from(StandardError) do |exception|
    puts "task_manage rescue: #{exception}"
    # SpiderJob.set(wait: 10.seconds).perform_later(@url, @source)
  end
end
