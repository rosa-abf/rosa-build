$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require 'rvm/capistrano'
require 'bundler/capistrano'
require 'airbrake/capistrano'

set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

set :rvm_type, :user

set :default_stage, "staging"
set :stages, %w(production staging)
require 'capistrano/ext/multistage'

# bundler bootstrap

# main details
ssh_options[:forward_agent] = true

set :application, "rosa_build"

set :repository,  "git@github.com:warpc/rosa-build.git"
# set :git_shallow_clone, 1
set :scm, "git"

set :user, "rosa"
set :use_sudo, false
set :deploy_to, "/srv/#{application}"

set :keep_releases, 3

task :symlink_config_files do
  run "mkdir -p #{deploy_to}/#{shared_dir}/config"

  run "yes y | cp -i #{release_path}/config/database.yml.sample #{deploy_to}/#{shared_dir}/config/database.yml"
  run "yes y | cp -i #{release_path}/config/application.yml.sample #{deploy_to}/#{shared_dir}/config/application.yml"


  run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  run "ln -nfs #{shared_path}/config/application.yml #{release_path}/config/application.yml"
end

task :symlink_downloads_dir do
  run "ln -nfs #{shared_path}/downloads/ #{release_path}/public/downloads"
end

task :generate_roles do
  run "cd #{deploy_to}/current ; RAILS_ENV=production bundle exec rake rights:generate"
  #run "cd #{deploy_to}/current ; RAILS_ENV=production bundle exec rake roles:load"
  run "cd #{deploy_to}/current ; RAILS_ENV=production bundle exec rake roles:apply"
end

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_release}/tmp/restart.txt"
    restart_dj
  end

  %w(start).each { |name| task name, :roles => :app do deploy.restart end }

  desc "Restart delayed job"
  task :restart_dj, :roles => :web do
    run "cd #{deploy_to}/current ; RAILS_ENV=production ./script/delayed_job stop; RAILS_ENV=production ./script/delayed_job start; true"
  end

  after "deploy:update_code", :roles => :web do
    symlink_config_files
    symlink_downloads_dir
    generate_roles
  end
end
