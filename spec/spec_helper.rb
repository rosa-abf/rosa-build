# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.filter_run_excluding anonymous_access: !(APP_CONFIG['anonymous_access'])

  config.before(:all) { init_test_root }
  config.after(:all)  { clear_test_root }
end

def set_session_for(user=nil)
  current_user = user.is_a?(Symbol) ? FactoryGirl.create(user) : user
  @request.env["devise.mapping"] = :user
  sign_in current_user
end

def http_login(user=nil, password = '123456')
  # FIXME: password constant is a bad choice...
  email = user.is_a?(String) ? user : user.try(:email)
  request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(email, password)
end

def stub_symlink_methods
  any_instance_of(Platform, symlink_directory: true)
  any_instance_of(Platform, remove_symlink_directory: true)
end

Resque.inline = true
APP_CONFIG['root_path']   = "#{Rails.root}/tmp/test_root"
APP_CONFIG['git_path']    = "#{Rails.root}/tmp/test_root"
APP_CONFIG['tmpfs_path']  = "#{Rails.root}/tmp/test_root"

def init_test_root
  clear_test_root
  %x(bash -c 'mkdir -p #{APP_CONFIG['root_path']}/{platforms,tmp}')
end

def clear_test_root
  %x(rm -Rf #{APP_CONFIG['root_path']})
end

def stub_redis
  @redis_instance = MockRedis.new
  allow(Redis).to receive(:new).and_return(@redis_instance)
  allow(Resque).to receive(:redis).and_return(@redis_instance)
end

def fill_project project
  %x(mkdir -p #{project.path} && cp -Rf #{Rails.root}/spec/tests.git/* #{project.path}) # maybe FIXME ?
end

def clean_projects_dir
  FileUtils.rm_rf "#{APP_CONFIG['git_path']}"
end
