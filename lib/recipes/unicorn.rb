Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    set :unicorn_binary, "bundle exec unicorn"
    set(:unicorn_pid) { "#{fetch :shared_path}/pids/unicorn.pid" }
    # set :unicorn_port, 8080

    task :start, roles: :app, except: { no_release: true } do
      run "cd #{fetch :current_path} && #{try_sudo} #{unicorn_binary} -l /tmp/#{fetch :application}_unicorn.sock -E #{rails_env} -c config/unicorn.rb -D" # -p #{unicorn_port}
    end
    task :stop, roles: :app, except: { no_release: true } do
      run "#{try_sudo} kill `cat #{unicorn_pid}`" rescue warn 'deploy:stop FAILED'
    end
    task :graceful_stop, roles: :app, except: { no_release: true } do
      run "#{try_sudo} kill -QUIT `cat #{unicorn_pid}`" rescue warn 'deploy:graceful_stop FAILED'
    end
    task :reload, roles: :app, except: { no_release: true } do
      run "#{try_sudo} kill -USR2 `cat #{unicorn_pid}`" rescue warn 'deploy:reload FAILED'
    end
    task :restart, roles: :app, except: { no_release: true } do
      reload
      #stop
      #start # blue pill will do it?
    end
  end
end
