APP_CONFIG = YAML.load_file("#{Rails.root}/config/application.yml")[Rails.env]

# Setup Smart HTTP GRack
require 'grack'
config = {:project_root => File.join(APP_CONFIG['root_path'], 'git_projects'), :git_path => '/opt/local/bin/git', :upload_pack => true, :receive_pack => true}
# Rosa::Application.config.middleware.insert_before ::ActionDispatch::Static, ::Grack::Handler, config
Rosa::Application.config.middleware.insert_after ::Rails::Rack::Logger, ::Grack::Handler, config
Rosa::Application.config.middleware.insert_before ::Grack::Handler, ::Grack::Auth

# Grit::Git.git_timeout = 60
