require 'resque/server'
require 'resque/status_server'
require 'resque_scheduler'
require 'resque_scheduler/server'

::ResqueServer = ::Resque::Server # need for CanCan

Resque::Mailer.default_queue_name = :notification
Resque::Mailer.excluded_environments = [:test]

unless Rails.env.test?
  PerformLater.config.enabled = true # this will default to false if unset
  Resque.schedule = YAML.load_file(File.join(Rails.root, 'config/resque_schedule.yml')) # load the schedule
end

Resque::Plugins::Status::Hash.expire_in = (24 * 60 * 60) # 24hrs in seconds

Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
Resque.after_fork do
  Resque.redis.client.reconnect
end