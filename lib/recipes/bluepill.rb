Capistrano::Configuration.instance(:must_exist).load do
  namespace :bluepill do
    set :bluepill_binary, "bundle exec bluepill --no-privileged"

    desc "Stop processes that bluepill is monitoring and quit bluepill"
    task :quit, :roles => [:app], :on_error => :continue do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} stop APP_NAME=#{fetch :application}"
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} quit APP_NAME=#{fetch :application}"
    end

    desc "Load bluepill configuration and start it"
    task :start, :roles => [:app] do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} load config/production.pill APP_NAME=#{fetch :application}"
    end

    desc "Prints bluepills monitored processes statuses"
    task :status, :roles => [:app] do
      run "cd #{fetch :current_path} && #{try_sudo} #{bluepill_binary} status APP_NAME=#{fetch :application}"
    end
  end
end
