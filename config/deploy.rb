# RVM bootstrap
$:.unshift(File.expand_path("~/.rvm/lib"))
require 'rvm/capistrano'
set :rvm_ruby_string, 'ree@rails-3.0.5'
set :rvm_type, :user

# bundler bootstrap
require 'bundler/capistrano'

# main details
set :application, "rosa_build"
set :user, "rosa_build"

default_run_options[:pty] = true
set :scm, "git"

set :deploy_to, "/var/www/#{application}"

set :domain, "abs.rosalab.ru"
set :port, 222

role :app, domain
role :web, domain
role :db,  domain, :primary => true
ssh_options[:auth_methods] = %w(publickey password)
set :use_sudo, false

set :repository,  "git@github.com:evilmartians/rosa-build.git"
set :branch, "master"
set :git_shallow_clone, 1
set :keep_releases, 3

task :symlink_config_files do
  run "mkdir -p #{deploy_to}/#{shared_dir}/config"

  run "yes n | cp -i #{release_path}/config/database.yml.sample #{deploy_to}/#{shared_dir}/config/database.yml"
  run "yes n | cp -i #{release_path}/config/application.yml.sample #{deploy_to}/#{shared_dir}/config/application.yml"


  run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml"
  run "ln -nfs #{deploy_to}/#{shared_dir}/config/application.yml #{release_path}/config/application.yml"
end

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "cd #{deploy_to}/current ; ([ -f tmp/pids/unicorn.pid ] && kill -USR2 `cat tmp/pids/unicorn.pid`); true"
#    restart_dj
  end

  %w(start).each { |name| task name, :roles => :app do deploy.restart end }

  desc "Restart delayed job"
  task :restart_dj, :roles => :web do
    run "cd #{deploy_to}/current ; RAILS_ENV=production ./script/delayed_job stop; RAILS_ENV=production ./script/delayed_job start; true"
  end

  desc "Rude restart application"
  task :rude_restart, :roles => :web do
    run "cd #{deploy_to}/current ; pkill unicorn; sleep 0.5; pkill -9 unicorn; sleep 0.5 ; unicorn_rails -c config/unicorn.rb -E production -D "
  end

  desc 'Bundle and minify the JS and CSS files'
  task :build_assets, :roles => :app do
    root_path    = File.expand_path(File.dirname(__FILE__) + '/..')
    assets_path  = "#{root_path}/public/assets"
    envs         = "RAILS_ENV=production"

    # Precaching assets
    run_locally "bash -c '#{envs} jammit'"

    # Uploading prechached assets
    top.upload assets_path, "#{current_release}/public", :via => :scp, :recursive => true
  end

  after "deploy:update_code", :roles => :web do
    build_assets
    symlink_config_files
  end

  after "deploy:migrate", :roles => :web do
    restart
  end
end

require 'hoptoad_notifier/capistrano'
