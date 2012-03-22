# -*- encoding : utf-8 -*-
APP_CONFIG = YAML.load_file("#{Rails.root}/config/application.yml")[Rails.env]

require 'modules'

# Setup Smart HTTP GRack
require 'grack'
config = {:project_root => File.join(APP_CONFIG['root_path'], 'git_projects'), :git_path => 'git', :upload_pack => true, :receive_pack => true}
# Rosa::Application.config.middleware.insert_before 0, ::Grack::Handler, config
Rosa::Application.config.middleware.insert_after ::Rails::Rack::Logger, ::Grack::Handler, config
Rosa::Application.config.middleware.insert_before ::Grack::Handler, ::Grack::Auth

Grit::Git.git_timeout = 60
# Grit.debug = true
GAP_REPO_PATH = '/tmp/gap_repo.git'
unless File.directory? GAP_REPO_PATH
  Grit::Repo.init_bare(GAP_REPO_PATH)
  # FileUtils.chmod "a-w", GAP_REPO_PATH
end

Dir[Rails.root.join("lib/ext/**/*.rb")].each {|f| require f}

# add rpm spec as mime type for *.spec files
types = [
  ["text/x-python",   ['py'],     '8bit'],
  ["text/x-rpm-spec", ['spec'],   '8bit'],
  ["text/x-csrc",     ['h', 'c'], '8bit'],
  ["text/x-c++src",   ['cpp'],    '8bit']
]
types.each do |type|
  MIME::Types.add MIME::Type.from_array(type)
end

# load datatables plugin
require Rails.root.join("lib/rails_datatables")
