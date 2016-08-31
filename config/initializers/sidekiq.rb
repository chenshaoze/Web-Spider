# require 'sidekiq'
# require 'sidekiq-status'
# require 'sidekiq/web'
# require 'sidekiq-status/web'
Sidekiq.configure_server do |config|
   config.server_middleware do |chain|
      # chain.add Sidekiq::Middleware::Server::RetryJobs, :max_retries => 0
      chain.remove Sidekiq::Middleware::Server::RetryJobs
      chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes # default
   end

   config.client_middleware do |chain|
    # accepts :expiration (optional)
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 30.minutes # default
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    # accepts :expiration (optional)
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 30.minutes # default
  end
end