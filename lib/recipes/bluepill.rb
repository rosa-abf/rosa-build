Capistrano::Configuration.instance(:must_exist).load do
  namespace :bluepill do
    set(:bluepill_binary) {"APP_NAME=#{fetch :application} bundle exec bluepill --no-privileged"}

    desc "Load bluepill configuration and start it"
    task :start, :roles => [:app] do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} load config/production.pill"
    end

    desc "Stop processes that bluepill is monitoring"
    task :stop, :roles => [:app], :on_error => :continue do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} stop"
    end

    task :restart, :roles => [:app] do
      # run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} restart #{fetch :application}"
      stop; start
    end

    desc "Stop processes that bluepill is monitoring and quit bluepill"
    task :quit, :roles => [:app] do
      # stop
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} quit"
    end

    desc "Prints bluepills monitored processes statuses"
    task :status, :roles => [:app] do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} status"
    end
  end
end
