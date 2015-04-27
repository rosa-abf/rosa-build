source 'https://rubygems.org'

gem 'rails', '4.1.10'

gem 'activeadmin',                      github: 'activeadmin'
gem 'pg'
gem 'schema_plus', '~> 1.5'
########
gem 'devise'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-google-oauth2'
gem 'omniauth-github'
# gem 'omniauth-openid', '~> 1.0.1'
gem 'pundit'

gem 'ancestry'
gem 'paperclip'
gem 'resque'
gem 'resque-status'
gem 'resque_mailer'
gem 'resque-scheduler', '~> 2.5.4'
gem 'perform_later', git: 'git://github.com/KensoDev/perform_later.git' # should be after resque_mailer
gem 'russian'
gem 'highline', '~> 1.6.20'
gem 'state_machines-activerecord'
gem 'redis-rails'

gem 'grack', git: 'git://github.com/rosa-abf/grack.git', require: 'git_http'
gem 'grit', git: 'git://github.com/rosa-abf/grit.git', tag: '2.6.17'
gem 'charlock_holmes'
gem 'github-linguist', '3.1.5', require: 'linguist'
gem 'diff-display'

# Wiki
gem 'gollum-lib', '~> 3.0'
gem 'redcarpet', '~> 3.2'
gem 'creole'
gem 'rdiscount'
# gem 'org-ruby'
gem 'RedCloth'
gem 'wikicloth'

gem 'newrelic_rpm'
gem 'whenever', require: false

gem 'jbuilder'
gem 'rails3-jquery-autocomplete'
gem 'sprockets'
gem 'will_paginate'
gem 'meta-tags', require: 'meta_tags'
gem 'haml-rails'
gem 'jquery-rails'
gem 'jquery-migrate-rails'
gem 'ruby-haml-js'
gem 'slim'
gem 'simple_form', '3.1.0.rc2'
gem 'friendly_id'

gem 'rack-throttle', '~> 0.3.0'
gem 'rest-client'
gem 'ohm', '~> 1.3.2' # Ohm 2 breaks the compatibility with previous versions.
gem 'ohm-expire', '~> 0.1.3'

gem 'ffi'

gem 'attr_encrypted'
gem 'gemoji'

# AngularJS related stuff
gem 'underscore-rails'
gem 'angularjs-rails'
gem 'ng-rails-csrf'
gem 'momentjs-rails'
gem 'angular-i18n'
gem 'js-routes'
gem 'soundmanager-rails'
gem 'angular-ui-bootstrap-rails'
gem 'angular-rails-templates'
gem 'ngmin-rails'

gem 'time_diff'

gem 'sass-rails'
gem 'coffee-rails'
gem 'bootstrap-sass'
gem 'font-awesome-rails'
gem 'zeroclipboard-rails'

gem 'compass-rails'
gem 'uglifier'
gem 'therubyracer', platforms: [:mri, :rbx]
gem 'therubyrhino', platforms: :jruby
gem 'sitemap_generator'

gem 'codemirror-rails', '~> 4.5'

source 'https://rails-assets.org' do
  gem 'rails-assets-notifyjs'
end

gem 'rack-utf8_sanitizer'

group :production do
  gem 'airbrake'
  #gem 'bluepill', '~> 0.0.60', require: false
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
