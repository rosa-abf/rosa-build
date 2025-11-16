base_path  = "/rosa-build"
#pidfile File.join(base_path, 'shared', 'pids', 'unicorn.pid')
#state_path File.join(base_path, 'shared', 'pids', 'puma.state')
bind 'unix:///rosa-build/tmp/sockets/rosa_build_jobs.sock'

environment ENV['RAILS_ENV'] || 'production'
threads *(ENV['PUMA_THREADS'] || '12,12').split(',')
workers ENV['PUMA_WORKERS'] || 5

preload_app!

on_worker_boot do
  Redis::Semaphore.new(:job_shift_lock, redis: Redis.new(url: ENV['REDIS_URL'])).delete! rescue nil
  if defined?(ActiveRecord::Base)
    ActiveSupport.on_load(:active_record) do
      ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished

      ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
      Rails.logger.info(ActiveRecord::Base.configurations)
    end
    # QC::Conn.connect
    Rails.logger.info('Connected to PG')
  end
end
