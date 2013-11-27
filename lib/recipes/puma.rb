# -*- encoding : utf-8 -*-
# Capistrano::Configuration.instance(:must_exist).load do
#   namespace :deploy do
#     # bundle exec puma -p $PORT -C config/puma.rb
#     set :puma_binary, "bundle exec puma"
#     set(:puma_pid) { "#{fetch :shared_path}/pids/unicorn.pid" }
#     # set :unicorn_port, 8080

#     task :start, :roles => :app, :except => { :no_release => true } do 
#       run "cd #{fetch :current_path} && #{try_sudo} #{puma_binary} -b unix:/tmp/#{fetch :application}_unicorn.sock -e #{rails_env} -d -C config/puma.rb" # -p #{unicorn_port}
#     end
#     task :stop, :roles => :app, :except => { :no_release => true } do 
#       run "#{try_sudo} kill `cat #{puma_pid}`" rescue warn 'deploy:stop FAILED'
#     end
#     task :graceful_stop, :roles => :app, :except => { :no_release => true } do
#       run "#{try_sudo} kill -QUIT `cat #{puma_pid}`" rescue warn 'deploy:graceful_stop FAILED'
#     end
#     task :reload, :roles => :app, :except => { :no_release => true } do
#       run "#{try_sudo} kill -USR2 `cat #{puma_pid}`" rescue warn 'deploy:reload FAILED'
#     end
#     task :restart, :roles => :app, :except => { :no_release => true } do
#       reload
#       #stop
#       #start # blue pill will do it?
#     end
#   end
# end

Capistrano::Configuration.instance(:must_exist).load do
  after 'deploy:stop', 'puma:stop'
  after 'deploy:start', 'puma:start'
  after 'deploy:restart', 'puma:restart'

  _cset(:puma_cmd)    { "#{fetch(:bundle_cmd, 'bundle')} exec puma" }
  _cset(:pumactl_cmd) { "#{fetch(:bundle_cmd, 'bundle')} exec pumactl" }
  _cset(:puma_env)    { fetch(:rack_env, fetch(:rails_env, 'production')) }
  _cset(:puma_state)  { "#{shared_path}/sockets/puma.state" }
  _cset(:puma_socket) { "unix://tmp/#{fetch :application}_unicorn.sock" }
  _cset(:puma_role)   { :app }

  namespace :puma do
    desc 'Start puma'
    task :start, :roles => lambda { puma_role }, :on_no_matching_servers => :continue do
      run "cd #{current_path} && #{puma_cmd} #{start_options}", :pty => false
    end

    desc 'Stop puma'
    task :stop, :roles => lambda { puma_role }, :on_no_matching_servers => :continue do
      run "cd #{current_path} && #{pumactl_cmd} -S #{state_path} stop"
    end

    desc 'Restart puma'
    task :restart, :roles => lambda { puma_role }, :on_no_matching_servers => :continue do
      begin
        run "cd #{current_path} && #{pumactl_cmd} -S #{state_path} restart"
      rescue Capistrano::CommandError => ex
        puts "Failed to restart puma: #{ex}\nAssuming not started."
        start
      end
    end

    desc 'Restart puma (phased restart)'
    task :phased_restart, :roles => lambda { puma_role }, :on_no_matching_servers => :continue do
      run "cd #{current_path} && #{pumactl_cmd} -S #{state_path} phased-restart"
    end

  end

  def start_options
    if config_file
      "-q -d -e #{puma_env} -C #{config_file}"
    else
      "-q -d -e #{puma_env} -b '#{puma_socket}' -S #{state_path} --control 'unix://#{shared_path}/sockets/pumactl.sock'"
    end
  end

  def config_file
    @_config_file ||= begin
      file = fetch(:puma_config_file, nil)
      file = "./config/puma/#{puma_env}.rb" if !file && File.exists?("./config/puma/#{puma_env}.rb")
      file
    end
  end

  def puma_env
    fetch(:rack_env, fetch(:rails_env, 'production'))
  end

  def state_path
    (config_file ? configuration.options[:state] : nil) || puma_state
  end

  def configuration
    require 'puma/configuration'

    config = Puma::Configuration.new(:config_file => config_file)
    config.load
    config
  end
end