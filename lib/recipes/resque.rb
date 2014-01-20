Capistrano::Configuration.instance(:must_exist).load do

  namespace :resque do
    task :start do
      start_workers
    end

    task :stop do
      stop_workers
    end

    task :restart do
      stop_workers
      start_workers
    end

    def rails_env
      fetch(:rails_env, false) ? "RAILS_ENV=#{fetch(:rails_env)}" : ''
    end

    def stop_workers
      # ps = 'ps aux | grep resque | grep -v grep'
      # run "#{ps} && kill -QUIT `#{ps} | awk '{ print $2 }'` || echo 'Workers already stopped!'"
      run "cd #{fetch :current_path} && #{rails_env} bundle exec rake resque:stop_workers"
    end

    def start_workers
      queue = [
        :publish_observer,
        :rpm_worker_observer,
        :iso_worker_observer,
        :fork_import,
        :hook,
        :clone_build,
        :notification
      ].join(',')
      run "cd #{fetch :current_path} && COUNT=#{workers_count} QUEUE=#{queue} #{rails_env} BACKGROUND=yes bundle exec rake resque:workers"
    end
  end
end
