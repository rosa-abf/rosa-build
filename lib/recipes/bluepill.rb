Capistrano::Configuration.instance(:must_exist).load do
  namespace :bluepill do
    set(:bluepill_binary) {"APP_NAME=#{fetch :application} bundle exec bluepill --no-privileged"}

    desc "Stop processes that bluepill is monitoring and quit bluepill"
    task :quit, :roles => [:app], :on_error => :continue do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} stop"
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} quit"
    end

    desc "Load bluepill configuration and start it"
    task :start, :roles => [:app] do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} load config/production.pill"
    end

    task :restart, :roles => [:app] do
      quit
      start
    end

    desc "Prints bluepills monitored processes statuses"
    task :status, :roles => [:app] do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} status"
    end
  end
end
