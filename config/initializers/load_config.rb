APP_CONFIG = YAML.load_file("#{Rails.root}/config/application.yml")[Rails.env]

require 'modules'

# Setup Smart HTTP GRack
require 'grack'
config = {:project_root => File.join(APP_CONFIG['root_path'], 'git_projects'), :git_path => 'git', :upload_pack => true, :receive_pack => true}
# Rosa::Application.config.middleware.insert_before 0, ::Grack::Handler, config
Rosa::Application.config.middleware.insert_after ::Rails::Rack::Logger, ::Grack::Handler, config
Rosa::Application.config.middleware.insert_before ::Grack::Handler, ::Grack::Auth

# Grit::Git.git_timeout = 60
