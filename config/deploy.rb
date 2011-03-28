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

after "deploy:update_code", :symlink_config_files

#before "deploy:update_code", "delayed_job:stop"
#after "deploy:symlink", "delayed_job:start"

#before "deploy:restart", :symlink_and_rebuild_sphinx

task :symlink_config_files do
  run "mkdir -p #{deploy_to}/#{shared_dir}/config"

  run "yes n | cp -i #{release_path}/config/database.yml.sample #{deploy_to}/#{shared_dir}/config/database.yml"
#  run "yes n | cp -i #{release_path}/config/config.yml.sample #{deploy_to}/#{shared_dir}/config/config.yml"
  run "yes n | cp -i #{release_path}/config/application.yml.sample #{deploy_to}/#{shared_dir}/config/application.yml"


  run "ln -nfs #{deploy_to}/#{shared_dir}/config/database.yml #{release_path}/config/database.yml"
#  run "ln -nfs #{deploy_to}/#{shared_dir}/config/config.yml #{release_path}/config/config.yml"
  run "ln -nfs #{deploy_to}/#{shared_dir}/config/application.yml #{release_path}/config/application.yml"

end

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "cd #{deploy_to}/current ; ([ -f tmp/pids/unicorn.pid ] && kill -USR2 `cat tmp/pids/unicorn.pid`); true"
#    run "touch #{current_path}/tmp/restart.txt"
    # run "kill -USR2 `cat /var/www/musicus/shared/pids/unicorn.pid` || true"
  end

  %w(start).each { |name| task name, :roles => :app do deploy.restart end }
end

#namespace :delayed_job do
#  desc "Start delayed_job process"
#  task :start, :roles => :app do
#    run "cd #{current_path}; RAILS_ENV=production script/delayed_job start"
#  end
#
#  desc "Stop delayed_job process"
#  task :stop, :roles => :app do
#    run "[ -d #{current_path} ] && cd #{current_path} && RAILS_ENV=production script/delayed_job stop || true"
#  end
#
#  desc "Restart delayed_job process"
#  task :restart, :roles => :app do
#    run "cd #{current_path}; RAILS_ENV=production script/delayed_job restart"
#  end
#end

#task :symlink_and_rebuild_sphinx, :roles => [:app] do
#  thinking_sphinx.stop
#  symlink_sphinx_indexes
#  thinking_sphinx.rebuild
#end

#task :symlink_sphinx_indexes, :roles => [:app] do
#  run "ln -nfs #{shared_path}/db/sphinx #{release_path}/db/sphinx"
#end

# TODO: How to setup it in rails3
#Dir[File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'hoptoad_notifier-*')].each do |vendored_notifier|
#  $: << File.join(vendored_notifier, 'lib')
#end
#

require 'hoptoad_notifier/capistrano'
