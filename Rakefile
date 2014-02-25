# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'resque/tasks'
require 'resque_scheduler/tasks'

# This fixes connection fail with Postgres server on new fork:
task "resque:setup" => :environment do
  Resque.after_fork do
    Resque.redis.client.reconnect
    Resque.schedule = YAML.load_file(File.join(Rails.root, 'config/resque_schedule.yml')) # load the schedule
  end  
  Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
end

Rosa::Application.load_tasks
