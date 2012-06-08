# -*- encoding : utf-8 -*-
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
      run "kill -QUIT `cat #{ fetch(:current_path) }/tmp/pids/resque.pid`"
    end

    def start_workers
      run "cd #{fetch :current_path} && COUNT=2 QUEUE=fork_and_import #{ rails_env } BACKGROUND=yes PIDFILE=#{ fetch(:current_path) }/tmp/pids/resque.pid bundle exec rake resque:workers"
    end
  end
end
