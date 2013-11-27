# -*- encoding : utf-8 -*-
base_path  = "/srv/rosa_build"

environment ENV['RAILS_ENV'] || 'production'
threads *(ENV['PUMA_THREADS'] || '1,6').split(',')
workers ENV['PUMA_WORKERS'] || 5

pidfile File.join(base_path, 'shared', 'pids', 'unicorn.pid')

preload_app!

on_worker_boot do
  if defined?(ActiveRecord::Base)
    ActiveSupport.on_load(:active_record) do
      ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
      ActiveRecord::Base.establish_connection
    end
    # QC::Conn.connect
    Rails.logger.info('Connected to PG')
  end

  # Redis.connect!
  # Rails.logger.info('Connected to Redis')
end