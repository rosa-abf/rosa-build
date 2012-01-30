# -*- encoding : utf-8 -*-
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
set :rvm_type, :user

require 'rvm/capistrano'
require 'bundler/capistrano'
require 'delayed/recipes'
require 'airbrake/capistrano'

set :whenever_command, "bundle exec whenever"
# require "whenever/capistrano"

require 'capistrano/ext/multistage'
set :default_stage, "staging"
# set :stages, %w(production staging pingwinsoft) # auto readed

# main details
ssh_options[:forward_agent] = true
default_run_options[:pty] = true

set :application, "rosa_build"
set(:deploy_to) { "/srv/#{application}" }
set :user, "rosa"
set :use_sudo, false
set :keep_releases, 3

set :scm, :git
set :repository,  "git@github.com:warpc/rosa-build.git"
set :deploy_via,  :remote_cache

require './lib/recipes/nginx'
require './lib/recipes/unicorn'
require './lib/recipes/bluepill'

namespace :deploy do
  task :stub_xml_rpc do
    path = File.join(release_path, 'config', 'environment.rb')
    code = %Q{\nrequire 'stub_xml_rpc'\n}
    puts "Stub XML RPC"
    run %Q{echo "#{code}" >> #{path}}
  end

  task :symlink_all, :roles => :app do
    run "mkdir -p #{fetch :shared_path}/config"
    
    # Setup DB
    run "cp -n #{fetch :release_path}/config/database.yml.sample #{fetch :shared_path}/config/database.yml"
    run "ln -nfs #{fetch :shared_path}/config/database.yml #{fetch :release_path}/config/database.yml"
    
    # Setup application
    run "cp -n #{fetch :release_path}/config/deploy/application.#{fetch :stage}.yml #{fetch :shared_path}/config/application.yml"
    run "ln -nfs #{fetch :shared_path}/config/application.yml #{fetch :release_path}/config/application.yml"

    # It will survive downloads folder between deployments
    run "mkdir -p #{fetch :shared_path}/downloads"
    run "ln -nfs #{fetch :shared_path}/downloads/ #{fetch :release_path}/public/downloads"
  end

  task :symlink_pids, :roles => :app do
    run "cd #{fetch :shared_path}/tmp && ln -nfs ../pids pids"
  end
end

after "deploy:update_code", "deploy:symlink_all", "deploy:migrate"
after "deploy:restart","bluepill:stop", "delayed_job:restart", "deploy:cleanup", "bluepill:start"
after "deploy:setup", "deploy:symlink_pids"

require 'cape'
namespace :rake_tasks do
  Cape do
    mirror_rake_tasks 'db:seeds'
  end
end
