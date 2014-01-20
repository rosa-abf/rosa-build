Capistrano::Configuration.instance(:must_exist).load do
  namespace :bluepill do
    set(:bluepill_binary) {"bundle exec bluepill --no-privileged"}

    namespace :processes do
      desc "Start processes that bluepill is monitoring"
      task :start, :roles => [:app] do
        run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} #{fetch :application} start"
      end

      desc "Stop processes that bluepill is monitoring"
      task :stop, :roles => [:app], :on_error => :continue do
        run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} #{fetch :application} stop"
      end

      desc "Restart processes that bluepill is monitoring"
      task :restart, :roles => [:app] do
        run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} #{fetch :application} restart"
      end

      desc "Prints bluepills monitored processes statuses"
      task :status, :roles => [:app] do
        run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} #{fetch :application} status"
      end
    end

    desc "Start a bluepill process and load a config"
    task :start, :roles => [:app] do
      run "cd #{fetch :current_path} && #{try_sudo} APP_NAME=#{fetch :application} #{bluepill_binary} load config/production.pill"
    end

    desc "Quit bluepill"
    task :quit, :roles => [:app] do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} #{fetch :application} stop"
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} #{fetch :application} quit"
    end

    desc "Completely restart bluepill and monitored services"
    task :restart, :roles => [:app] do
      processes.stop; stop; start
    end

    desc "Stop bluepill and monitored services"
    task :stop, :roles => [:app] do
      processes.stop
    end
  end
end
