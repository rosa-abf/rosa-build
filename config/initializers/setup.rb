# -*- encoding : utf-8 -*-
Dir[Rails.root.join("lib/ext/**/*.rb")].each {|f| require f}
require 'modules'
require 'plugins'

# Setup Smart HTTP GRack
config = {:project_root => File.join(APP_CONFIG['git_path'], 'git_projects'), :git_path => 'git', :upload_pack => true, :receive_pack => true}
# Rosa::Application.config.middleware.insert_before 0, ::Grack::Handler, config
Rosa::Application.config.middleware.insert_after ::Rails::Rack::Logger, ::Grack::Handler, config
Rosa::Application.config.middleware.insert_before ::Grack::Handler, ::Grack::Auth

Rosa::Application.config.action_mailer.default_url_options = { :host => APP_CONFIG['action_mailer_host'] } if APP_CONFIG['action_mailer_host']

# Workaround for https://github.com/github/gemoji/pull/18
Rosa::Application.config.assets.paths << Emoji.images_path