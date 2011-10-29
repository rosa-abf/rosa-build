$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require 'rvm/capistrano'
require 'bundler/capistrano'
require 'airbrake/capistrano'

set :rvm_type, :user

# bundler bootstrap

# main details
ssh_options[:forward_agent] = true

set :application, "rosa_build"

set :repository,  "git@github.com:warpc/rosa-build.git"
set :branch, "master"
# set :git_shallow_clone, 1
set :scm, "git"

set :user, "rosa"
set :domain, "195.19.76.12" # "abs.rosalab.ru"
set :port, 1822 # 222
set :use_sudo, false
set :deploy_to, "/srv/#{application}"

role :app, domain
role :web, domain
role :db,  domain, :primary => true

set :keep_releases, 3


task :symlink_config_files do
  run "mkdir -p #{deploy_to}/#{shared_dir}/config"

  run "yes y | cp -i #{release_path}/config/database.yml.sample #{deploy_to}/#{shared_dir}/config/database.yml"
  run "yes y | cp -i #{release_path}/config/application.yml.sample #{deploy_to}/#{shared_dir}/config/application.yml"


  run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  run "ln -nfs #{shared_path}/config/application.yml #{release_path}/config/application.yml"
end

task :generate_roles do
  run "cd #{deploy_to}/current ; RAILS_ENV=production bundle exec rake rights:generate"
  run "cd #{deploy_to}/current ; RAILS_ENV=production bundle exec rake roles:load"
  run "cd #{deploy_to}/current ; RAILS_ENV=production bundle exec rake roles:apply"
end

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    ## DISABLED: run "cd #{deploy_to}/current ; ([ -f tmp/pids/unicorn.pid ] && kill -USR2 `cat tmp/pids/unicorn.pid`); true"
    run ["#{current_path}/script/unicorn reload"].join("; ")
    restart_dj
  end

  %w(start).each { |name| task name, :roles => :app do deploy.restart end }

  desc "Restart delayed job"
  task :restart_dj, :roles => :web do
    run "cd #{deploy_to}/current ; RAILS_ENV=production ./script/delayed_job stop; RAILS_ENV=production ./script/delayed_job start; true"
  end

#  desc 'Bundle and minify the JS and CSS files'
#  task :build_assets, :roles => :app do
#    root_path    = File.expand_path(File.dirname(__FILE__) + '/..')
#    assets_path  = "#{root_path}/public/assets"
#    envs         = "RAILS_ENV=production"
#
#    # Precaching assets
#    run_locally "bash -c '#{envs} jammit'"
#
#    # Uploading prechached assets
#    top.upload assets_path, "#{current_release}/public", :via => :scp, :recursive => true
#  end

  after "deploy:update_code", :roles => :web do
#    build_assets
    symlink_config_files
    generate_roles
  end
  
end
