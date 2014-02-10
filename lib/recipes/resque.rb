Capistrano::Configuration.instance(:must_exist).load do

  namespace :resque do
    task :start do
      start_workers
      invoke "resque:scheduler:start"
    end

    task :stop do
      stop_workers
      invoke "resque:scheduler:stop"
    end

    task :restart do
      stop_workers
      start_workers
      invoke "resque:scheduler:restart"
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

    def remote_file_exists?(full_path)
      'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
    end

    namespace :scheduler do

      desc "See current scheduler status"
      task :status do
        pid = "#{fetch :current_path}/tmp/pids/scheduler.pid"
        if remote_file_exists?(pid)
          info capture(:ps, "-f -p $(cat #{pid}) | sed -n 2p")
        end
      end

      desc "Starts resque scheduler with default configs"
      task :start do
        pid = "#{fetch :current_path}/tmp/pids/scheduler.pid"
        run "cd #{fetch :current_path} && #{rails_env} PIDFILE=#{pid} BACKGROUND=yes VERBOSE=1 MUTE=1 bundle exec rake resque:scheduler"
      end

      desc "Stops resque scheduler"
      task :stop do
        pid = "#{fetch :current_path}/tmp/pids/scheduler.pid"
        if remote_file_exists?(pid)
          run "cd #{fetch :current_path} && kill -s QUIT $(cat #{pid}); rm #{pid}"
        end
      end

      task :restart do
        invoke "resque:scheduler:stop"
        invoke "resque:scheduler:start"
      end
    end

  end

end
