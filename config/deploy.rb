$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
set :rvm_type, :user
require 'rvm/capistrano'
require 'bundler/capistrano'
require 'delayed/recipes'
require 'airbrake/capistrano'
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

set :default_stage, "staging"
# set :stages, %w(production staging pingwinsoft ui) # auto readed
require 'capistrano/ext/multistage'

# main details
ssh_options[:forward_agent] = true

set :application, "rosa_build"
set :deploy_to, "/srv/#{application}"
set :user, "rosa"
set :use_sudo, false
set :keep_releases, 3

set :repository,  "git@github.com:warpc/rosa-build.git"
# set :git_shallow_clone, 1
set :scm, "git"
# set :deploy_via, :copy
# set :copy_cache, true

set :unicorn_binary, "bundle exec unicorn"
set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"
set :unicorn_port, 8080

require 'lib/recipes/nginx'
namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do 
    run "cd #{current_path} && #{try_sudo} #{unicorn_binary} -c #{unicorn_config} -p #{unicorn_port} -E #{rails_env} -D"
  end
  task :stop, :roles => :app, :except => { :no_release => true } do 
    run "#{try_sudo} kill `cat #{unicorn_pid}`"
  end
  task :graceful_stop, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s QUIT `cat #{unicorn_pid}`"
  end
  task :reload, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s USR2 `cat #{unicorn_pid}`"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end
  # task :restart, :roles => :app, :except => { :no_release => true } do
  #   run "touch #{current_release}/tmp/restart.txt"
  # end

  task :stub_xml_rpc do
    path = File.join(current_path, 'config', 'environment.rb')
    code = %Q{\nrequire 'stub_xml_rpc'\n}
    puts "Stub XML RPC"
    run %Q{echo "#{code}" >> #{path}}
  end

  task :symlink_config_files, :roles => :web do
    run "mkdir -p #{deploy_to}/#{shared_dir}/config"

    run "yes y | cp -i #{release_path}/config/database.yml.sample #{deploy_to}/#{shared_dir}/config/database.yml"
    run "yes y | cp -i #{release_path}/config/application.yml.sample #{deploy_to}/#{shared_dir}/config/application.yml"

    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/application.yml #{release_path}/config/application.yml"
  end

  task :symlink_downloads_dir, :roles => :web do
    run "ln -nfs #{shared_path}/downloads/ #{release_path}/public/downloads"
  end

  task :symlink_tmp_dir, :roles => :web do
    run "ln -nfs #{shared_path}/tmp/ #{release_path}/tmp"
    run "mkdir -p #{release_path}/tmp/mount"
    run "mkdir -p #{release_path}/tmp/umount"
  end
end

after "deploy:update_code", "deploy:symlink_config_files", "deploy:symlink_downloads_dir", "deploy:symlink_tmp_dir", "deploy:migrate"
after "deploy:restart", "delayed_job:restart", "deploy:cleanup"
