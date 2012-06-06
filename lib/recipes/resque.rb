## -*- encoding : utf-8 -*-
#Capistrano::Configuration.instance(:must_exist).load do
#
#  require 'resque/server'
#
#  namespace :resque do
#    task :start do
#      start_workers
#    end
#
#    task :stop do
#      stop_workers
#    end
#
#    task :restart do
#      stop_workers
#      start_workers
#    end
#
#    def rails_env
#      fetch(:rails_env, false) ? "RAILS_ENV=#{fetch(:rails_env)}" : ''
#    end
#
#    def stop_workers
#      pids = Array.new
#
#      Resque.workers.each do |worker|
#        pids << worker.to_s.split(/:/)[1]
#      end
#
#      if pids.size > 0
#        system("kill -QUIT #{pids.join(' ')}")
#      end
#    end
#
#    def start_workers
#      run "cd #{fetch :release_path} && QUEUE=* #{ rails_env } bundle exec rake resque:work &"
#    end
#  end
#end
