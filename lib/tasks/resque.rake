namespace :resque do
  desc 'Stop all Resque workers'
  task stop_workers: :environment do
    pids = []
    Resque.workers.each do |worker|
      pids << worker.to_s.split(/:/).second
    end
    system("kill -QUIT #{pids.join(' ')}") if pids.size > 0
  end

  # This fixes connection fail with Postgres server on new fork:
  task setup: :environment do
    Resque.after_fork do
      Resque.redis.client.reconnect
    end  
    Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
  end

  task scheduler_setup: :environment do
    Resque.schedule = YAML.load_file(Rails.root.join('config', 'resque_schedule.yml'))
  end

end
