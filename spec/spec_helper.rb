# -*- encoding : utf-8 -*-
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
  config.mock_with :rr
  #config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
end

def set_session_for(user=nil)
  current_user = user.is_a?(Symbol) ? Factory.create(user) : user
  @request.env["devise.mapping"] = :user
  sign_in current_user
end

def stub_rsync_methods
  any_instance_of(Platform, :mount_directory_for_rsync => true)
  any_instance_of(Platform, :umount_directory_for_rsync => true)
end

def test_git_commit(project)
  project.git_repository.repo.index.add('test', 'TEST')
  project.git_repository.repo.index.commit('Test commit')
end

Delayed::Worker.delay_jobs = false # Execute all jobs realtime

# Add testing root_path
%x(rm -Rf #{Rails.root}/tmp/test_root)
%x(mkdir -p #{Rails.root}/tmp/test_root)
APP_CONFIG['root_path'] = "#{Rails.root}/tmp/test_root"
