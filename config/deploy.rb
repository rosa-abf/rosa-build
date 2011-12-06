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
default_run_options[:pty] = true

set :application, "rosa_build"
set(:deploy_to) { "/srv/#{application}" }
set :user, "rosa"
set :use_sudo, false
set :keep_releases, 3

set :repository,  "git@github.com:warpc/rosa-build.git"
# set :git_shallow_clone, 1
set :scm, "git"
# set :deploy_via, :copy
# set :copy_cache, true

require 'lib/recipes/nginx'
require 'lib/recipes/unicorn'
namespace :deploy do
  # task :restart, :roles => :app, :except => { :no_release => true } do
  #   run "touch #{current_release}/tmp/restart.txt"
  # end

  task :stub_xml_rpc do
    path = File.join(release_path, 'config', 'environment.rb')
    code = %Q{\nrequire 'stub_xml_rpc'\n}
    puts "Stub XML RPC"
    run %Q{echo "#{code}" >> #{path}}
  end

  task :symlink_all, :roles => :web do
    # run "mkdir -p #{fetch :shared_path}/config"
    # Never do this!!!
    # run "yes y | cp -i #{fetch :release_path}/config/database.yml.sample #{fetch :shared_path}/config/database.yml"
    # run "yes y | cp -i #{fetch :release_path}/config/application.yml.sample #{fetch :shared_path}/config/application.yml"

    run "ln -nfs #{fetch :shared_path}/config/database.yml #{fetch :release_path}/config/database.yml"
    run "ln -nfs #{fetch :shared_path}/config/application.yml #{fetch :release_path}/config/application.yml"

    run "ln -nfs #{fetch :shared_path}/downloads/ #{fetch :release_path}/public/downloads"

    run "ln -nfs #{fetch :shared_path}/tmp/ #{fetch :release_path}/tmp"
    run "mkdir -p #{fetch :release_path}/tmp/mount"
    run "mkdir -p #{fetch :release_path}/tmp/umount"
  end
end

after "deploy:update_code", "deploy:symlink_all", "deploy:migrate"
after "deploy:restart", "delayed_job:restart", "deploy:cleanup"

require 'cape'
namespace :rake_tasks do
  Cape do
    # mirror_rake_tasks
    mirror_rake_tasks 'db:seeds'
  end
end
