source 'https://rubygems.org'

gem 'rails', '3.2.17'
gem 'redhillonrails_core', git: 'git://github.com/rosa-abf/redhillonrails_core.git', branch: 'rails31' # '~> 2.0.0.pre' # deprecated

gem 'pg', '~> 0.14.0'
gem 'activerecord-postgres-hstore'

gem 'devise', '~> 2.2.3'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'omniauth-github'
# gem 'omniauth-openid', '~> 1.0.1'
gem 'cancan', '1.6.7' # 1.6.8 fail specs with strange error

gem 'ancestry', '~> 1.3.0'
gem 'paperclip', '~> 4.1.0'
gem 'resque', '~> 1.24'
gem 'resque-status', '~> 0.3.3'
gem 'resque_mailer', '~> 2.2'
gem 'resque-scheduler'
# gem 'perform_later', '~> 1.3.0' # should be after resque_mailer
gem 'perform_later', git: 'git://github.com/KensoDev/perform_later.git' # should be after resque_mailer
gem 'russian', '~> 0.6.0'
gem 'highline', '~> 1.6.11'
gem 'state_machine'
gem 'redis-rails'

gem 'grack', git: 'git://github.com/rosa-abf/grack.git', require: 'git_http'
gem 'grit', git: 'git://github.com/rosa-abf/grit.git'
gem 'charlock_holmes', '~> 0.6.9'
gem 'github-linguist', '~> 2.3.4', require: 'linguist'
gem 'diff-display', '~> 0.0.1'

# Wiki
gem "gollum", '~> 2.1.3'
gem "redcarpet", '~> 2.2.2'
gem 'creole'
gem 'rdiscount'
# gem 'org-ruby'
gem 'RedCloth'
gem 'wikicloth'

# gem 'unicorn', '~> 4.3.1', platforms: [:mri, :rbx]
gem 'trinidad', '~> 1.0.2', platforms: :jruby

gem 'newrelic_rpm'
# gem 'whenever', '~> 0.7.3', require: false
gem 'whenever', '~> 0.9.0', require: false

gem 'jbuilder', '~> 1.4.2'
gem 'rails3-jquery-autocomplete', '~> 1.0.7'
gem 'will_paginate', '~> 3.0.3'
gem 'meta-tags', '~> 1.2.5', require: 'meta_tags'
gem "haml-rails", '~> 0.3.4'
gem 'jquery-rails', '~> 2.0.2'
gem 'ruby-haml-js', '~> 0.0.3'
gem 'friendly_id'

gem 'rack-throttle'
gem 'rest-client', '~> 1.6.6'
gem 'ohm'
gem 'ohm-expire'

gem 'ffi'

gem 'attr_encrypted', '1.2.1'
gem "gemoji", "~> 1.2.1", require: 'emoji/railtie'

# AngularJS related stuff
gem 'underscore-rails'
gem 'angularjs-rails'
gem 'ng-rails-csrf'
gem 'momentjs-rails'
gem 'angular-i18n', '0.1.2'
gem 'js-routes'
gem 'soundmanager-rails'

gem 'time_diff'

group :assets do
  gem 'sass-rails', '~> 3.2.5'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'compass-rails', '~> 1.0.3'
  gem 'uglifier', '~> 1.2.4'
  gem 'therubyracer', '~> 0.12.1', platforms: [:mri, :rbx]
  gem 'therubyrhino', '~> 1.73.1', platforms: :jruby
  gem 'turbo-sprockets-rails3'
end

group :production do
  gem "airbrake", '~> 3.1.2'
  gem 'bluepill', '~> 0.0.60', require: false
  # gem 'le'
  gem 'logglier'
  gem 'puma'
end

group :development do
  gem 'mailcatcher' # 'letter_opener'
  gem 'rails3-generators'
  gem 'hirb'
  gem 'shotgun'
  # deploy
  gem 'capistrano', require: false
  gem 'rvm-capistrano', require: false
  gem 'cape', require: false
  gem 'capistrano_colors', require: false
  # Better Errors & RailsPanel
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'localeapp'
  gem 'skype'
  #gem 'ruby-dbus' if RUBY_PLATFORM =~ /linux/i # Error at deploy
end

group :test do
  gem 'rspec-rails',        '~> 2.11.0', group: 'development'
  gem 'factory_girl_rails', '~> 4.0.0'
  gem 'rr',                 '~> 1.0.4'
  gem 'shoulda'
  gem 'mock_redis',         '0.6.2'
  gem 'rake'
end
