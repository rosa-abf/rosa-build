source 'http://rubygems.org'

gem 'rails', '3.0.11' #, :git => 'git://github.com/rails/rails.git'

gem 'pg', '~> 0.11.0'
gem 'silent-postgres', '~> 0.1.1'
gem 'redhillonrails_core', '~> 1.2.0' # deprecated
# gem 'schema_plus', '~> 0.2.1' # buggy shit!

gem 'devise', '~> 1.5.2'
gem 'omniauth', '~> 1.0.1'
gem 'omniauth-openid', '~> 1.0.1'
gem 'cancan', '~> 1.6.7'

gem "haml-rails", '~> 0.3.4'
# gem "compass", '~> 0.11.5' # update when it will be needed
gem 'jammit'
gem "yui-compressor", "0.9.5" # Higher versions depends on Platform gem which conflicts with Platform model
gem 'rails3-jquery-autocomplete'

gem 'ancestry', '~> 1.2.4'
gem 'paperclip', "~> 2.5"
gem "will_paginate", "~> 3.0.2"
gem 'meta-tags', '~> 1.2.4', :require => 'meta_tags'
gem "russian"

gem 'grack', :git => 'git://github.com/rdblue/grack.git', :require => 'git_http'
gem "grit", :git => 'git://github.com/mojombo/grit.git', :branch => 'master'

gem 'whenever', :require => false
gem 'delayed_job', '2.1.4'
gem 'highline', '~> 1.6.8'

# Wiki
gem "gollum", "1.3.1"
gem "redcarpet", "1.17.2"
gem 'creole'
gem 'rdiscount'
#gem 'org-ruby'
gem 'RedCloth'
gem 'wikicloth'

# XML-RPC support
gem "rails-xmlrpc", '~> 0.3.6' # :git => 'git://github.com/chipiga/rails-xmlrpc.git'

gem 'unicorn', '~> 4.1.1'

group :production do
  gem "airbrake", '~> 3.0.5'
  gem 'bluepill', :require => false
end

gem 'newrelic_rpm'

group :development do
  gem 'mailcatcher' # 'letter_opener'
  gem 'rails3-generators'
  gem 'web-app-theme'
  gem 'hpricot'
  gem 'ruby_parser'

  gem 'hirb'
  gem 'shotgun'

  # deploy
  gem 'capistrano', :require => false
  gem 'capistrano-ext', :require => false
  gem 'cape', :require => false
  gem 'capistrano_colors', :require => false
end

group :development, :test do
  gem 'rspec-rails',        '~> 2.7.0'
  gem 'factory_girl_rails', '~> 1.4.0'
  gem 'rr'
end

# group :test do
#   gem 'spork',              '>= 0.9.0.rc9'
#   gem 'guard-spork',        '~> 0.3.1'
#   gem 'guard-rspec',        '~> 0.5.0'
#   gem 'guard-bundler',      '~> 0.1.3'
# 
#   gem 'rb-fsevent', '>= 0.4.3', :require => false
#   gem 'growl',      '~> 1.0.3', :require => false
#   gem 'rb-inotify', '>= 0.8.6', :require => false
#   gem 'libnotify',  '~> 0.5.7', :require => false
# end
