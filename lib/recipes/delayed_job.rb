# -*- encoding : utf-8 -*-
Capistrano::Configuration.instance(:must_exist).load do
  namespace :delayed_job do
    def dj_queues
      %w(hook default)
    end

    def rails_env
      fetch(:rails_env, false) ? "RAILS_ENV=#{fetch(:rails_env)}" : ''
    end

    def roles
      fetch(:delayed_job_server_role, :app)
    end

    desc "Stop the delayed_job process"
    task :stop, :roles => lambda { roles } do
      dj_queues.each do |queue|
        run "cd #{current_path};#{rails_env} script/delayed_job --pid-dir=#{shared_path}/pids/#{queue} stop"
      end
    end

    desc "Start the delayed_job process"
    task :start, :roles => lambda { roles } do
      dj_queues.each do |queue|
        run "cd #{current_path};#{rails_env} script/delayed_job --queue=#{queue} -p #{queue} --pid-dir=#{shared_path}/pids/#{queue} start"
      end
    end

    desc "Restart the delayed_job process"
    task :restart, :roles => lambda { roles } do
      dj_queues.each do |queue|
        run "cd #{current_path};#{rails_env} script/delayed_job --queue=#{queue} -p #{queue} --pid-dir=#{shared_path}/pids/#{queue} restart"
      end
    end
  end
end
