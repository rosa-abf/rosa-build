# -*- encoding : utf-8 -*-
Capistrano::Configuration.instance(:must_exist).load do
  namespace :delayed_job do
    def dj_queues
      %w(fork import hook default)
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
        run "cd #{current_path};#{rails_env} script/delayed_job --pid-dir=#{current_path}/tmp/#{queue}_pids stop"
      end
    end

    desc "Start the delayed_job process"
    task :start, :roles => lambda { roles } do
      dj_queues.each do |queue|
        run "cd #{current_path};#{rails_env} script/delayed_job --queue=#{queue} -p #{queue} --pid-dir=#{current_path}/tmp/#{queue}_pids  start"
      end
    end

    desc "Restart the delayed_job process"
    task :restart, :roles => lambda { roles } do
      run "cd #{current_path};#{rails_env} script/delayed_job --queue=#{queue} -p #{queue} --pid-dir=#{current_path}/tmp/#{queue}_pids restart"
    end
  end
end
