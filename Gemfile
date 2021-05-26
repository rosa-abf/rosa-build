source 'https://rubygems.org'

gem 'rails'

gem 'activeadmin'
gem 'pg'
gem 'schema_plus'
gem 'devise'
gem 'pundit'

gem 'ancestry'
gem 'paperclip'
gem 'resque'
gem 'resque-status'
gem 'resque_mailer'
gem 'resque-scheduler', '~> 2.5.4'
gem 'perform_later', git: 'git://github.com/KensoDev/perform_later.git' # should be after resque_mailer
gem 'russian'
gem 'state_machines-activerecord'
gem 'redis-rails'

gem 'grack', git: 'git://github.com/rosa-abf/grack.git'
gem 'grit', git: 'git://github.com/rosa-abf/grit.git', branch: 'rosa'
gem 'charlock_holmes'
gem 'github-linguist', require: 'linguist'
gem 'diff-display'

# Wiki
gem 'gollum-lib', '~> 3.0'
gem 'redcarpet', '~> 3.5'
gem 'creole'
gem 'rdiscount'
gem 'RedCloth'
gem 'wikicloth'

gem 'jbuilder'
gem 'rails3-jquery-autocomplete'
gem 'sprockets'
gem 'will_paginate'
gem 'haml-rails'
gem 'jquery-rails'
gem 'slim'
gem 'simple_form', '3.1.0.rc2'
gem 'friendly_id'

gem 'rest-client'
gem 'ohm', '~> 1.3.2' # Ohm 2 breaks the compatibility with previous versions.
gem 'ohm-expire', '~> 0.1.3'

gem 'ffi'

gem 'attr_encrypted'
gem 'gemoji'

gem 'js-routes'

gem 'time_diff'

gem 'sass-rails'
gem 'coffee-rails'
gem 'bootstrap-sass'
gem 'font-awesome-rails'

gem 'uglifier'

gem 'codemirror-rails', '~> 4.5'

gem 'sentry-raven'

gem 'rails-assets-notifyjs', '0.3.2', path: 'vendor/gems/rails-assets-notifyjs-0.3.2'

gem 'rack-utf8_sanitizer'
gem 'redis-semaphore'
gem 'connection_pool'

gem 'recaptcha'

gem 'pygments.rb'

group :production do
  gem 'puma'
end

group :development do
  gem 'mailcatcher'
  gem 'rack-mini-profiler', require: false
end

group :development, :test do
  gem 'rspec-rails'
end

group :test do
  gem 'factory_girl_rails'
  gem 'rr'
  gem 'shoulda'
  gem 'shoulda-matchers'
  gem 'mock_redis'
  gem 'webmock'
  gem 'rake'
  gem 'test_after_commit'
  gem 'timecop'
end
