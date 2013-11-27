# -*- encoding : utf-8 -*-
Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    # bundle exec puma -p $PORT -C config/puma.rb
    set :puma_binary, "bundle exec puma"
    set(:puma_pid) { "#{fetch :shared_path}/pids/unicorn.pid" }
    # set :unicorn_port, 8080

    task :start, :roles => :app, :except => { :no_release => true } do 
      run "cd #{fetch :current_path} && #{try_sudo} #{puma_binary} -b unix:/tmp/#{fetch :application}_unicorn.sock -e #{rails_env} -d -C config/puma.rb" # -p #{unicorn_port}
    end
    task :stop, :roles => :app, :except => { :no_release => true } do 
      run "#{try_sudo} kill `cat #{puma_pid}`" rescue warn 'deploy:stop FAILED'
    end
    task :graceful_stop, :roles => :app, :except => { :no_release => true } do
      run "#{try_sudo} kill -QUIT `cat #{puma_pid}`" rescue warn 'deploy:graceful_stop FAILED'
    end
    task :reload, :roles => :app, :except => { :no_release => true } do
      run "#{try_sudo} kill -USR2 `cat #{puma_pid}`" rescue warn 'deploy:reload FAILED'
    end
    task :restart, :roles => :app, :except => { :no_release => true } do
      reload
      #stop
      #start # blue pill will do it?
    end
  end
end
