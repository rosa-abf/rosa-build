source 'http://rubygems.org'

gem 'rails', '3.0.10' #, :git => 'git://github.com/rails/rails.git'

gem 'pg', '~> 0.11.0'
gem 'silent-postgres', '~> 0.1.1'

gem 'devise', '~> 1.4.8'
gem 'omniauth', '~> 0.3.0'
gem 'oa-openid', '~> 0.3.0', :require => 'omniauth/openid'
gem 'cancan', '~> 1.6.7'

gem "haml-rails", '~> 0.3.4'
gem "compass", '~> 0.11.5'
gem 'jammit'
gem "yui-compressor", "0.9.5" # Higher versions depends on Platform gem which conflicts with Platform model

gem 'paperclip', "~> 2.3"
gem "will_paginate", "~> 3.0.2"
gem "russian"

gem "grit"
gem 'delayed_job'
gem 'unicorn'

group :production do
  gem "airbrake"
  # gem 'newrelic_rpm', '~> 3.1.1'
end

group :development do
  # gem 'letter_opener'
  gem 'rails3-generators'
  gem 'web-app-theme'
  gem 'hpricot'
  gem 'ruby_parser'

  # debug
  gem 'ruby-debug'
  # gem 'looksee'
  # gem 'awesome_print'
  # gem 'wirble'
  # gem 'hirb'
  # gem 'rails-footnotes', '>= 3.7.5.rc4' # this shit is very buggy don't forget to switch it off back

  # deploy
  gem 'capistrano', :require => false
  gem 'capistrano-ext', :require => false
  # gem 'capistrano-exts', :require => false #, :git => 'git://github.com/chipiga/capistrano-exts.git'
  # gem 'capistrano-recipes', :require => false
  gem 'capistrano_colors', :require => false
end

group :development, :test do
  gem 'mysql2', '<= 0.2.9'
end

group :test do
  gem 'rspec-rails',        '~> 2.6.1'
  gem 'factory_girl_rails', '~> 1.2.0'
  # gem 'spork',              '>= 0.9.0.rc9'
  # gem 'guard-spork',        '~> 0.3.1'
  # gem 'guard-rspec',        '~> 0.5.0'
  # gem 'guard-bundler',      '~> 0.1.3'
  # 
  # gem 'rb-fsevent', '>= 0.4.3', :require => false
  # gem 'growl',      '~> 1.0.3', :require => false
  # gem 'rb-inotify', '>= 0.8.6', :require => false
  # gem 'libnotify',  '~> 0.5.7', :require => false
end
