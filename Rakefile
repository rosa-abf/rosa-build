# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'resque/tasks'
# require 'resque-scheduler/tasks' # FIXME upgrade
# load    'tasks/emoji.rake' # FIXME upgrade

Rosa::Application.load_tasks
# Update js-routes file before javascript build
task "assets:precompile" => "js:routes"
task "assets:precompile" => "angular:patch"
task "assets:build" => "assets:precompile"

