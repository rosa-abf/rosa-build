Capistrano::Configuration.instance(:must_exist).load do
  namespace :bluepill do
    set(:bluepill_binary) {"bundle exec bluepill --no-privileged"}

    desc "Load bluepill configuration and start it"
    task :start, :roles => [:app] do
      run "cd #{fetch :current_path} && #{try_sudo} APP_NAME=#{fetch :application} #{bluepill_binary} load config/production.pill"
    end

    desc "Stop processes that bluepill is monitoring"
    task :stop, :roles => [:app], :on_error => :continue do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} #{fetch :application} stop"
    end

    task :restart, :roles => [:app] do
      # run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} #{fetch :application} restart"
      stop; quit; start
    end

    desc "Stop processes that bluepill is monitoring and quit bluepill"
    task :quit, :roles => [:app] do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} #{fetch :application} quit"
    end

    desc "Prints bluepills monitored processes statuses"
    task :status, :roles => [:app] do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} #{fetch :application} status"
    end
  end
end
