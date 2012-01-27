source 'http://rubygems.org'

gem 'rails', '3.0.11' #, :git => 'git://github.com/rails/rails.git'

gem 'pg', '~> 0.11.0'
gem 'silent-postgres', '~> 0.1.1'

gem 'devise', '~> 1.5.2'
gem 'omniauth', '~> 1.0.1'
gem 'omniauth-openid', '~> 1.0.1'
gem 'cancan', '~> 1.6.7'
#gem 'bitmask_attributes'

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

# gem 'ghoul_grack', '~> 0.0.1'
gem 'grack', :git => 'git://github.com/rdblue/grack.git', :require => 'git_http'
gem "grit"
gem 'whenever', :require => false
gem 'delayed_job'
gem 'highline', '~> 1.6.8'

# Wiki
gem "gollum", "1.3.1"
gem "redcarpet", "1.17.2"
gem 'creole'
gem 'rdiscount'
gem 'org-ruby'
gem 'RedCloth'
gem 'wikicloth'

# XML-RPC support
# gem 'actionwebservice' #, :git => 'git://github.com/ywen/actionwebservice.git'
gem "rails-xmlrpc", '~> 0.3.6' # :git => 'git://github.com/chipiga/rails-xmlrpc.git'

# gem 'passenger', '~> 3.0.11'
gem 'unicorn', '~> 4.1.1'

group :production do
  gem "airbrake", '~> 3.0.5'
  gem 'newrelic_rpm'
  gem 'bluepill', :require => false
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
#  gem 'wirble'
  gem 'hirb'
  # gem 'rails-footnotes', '>= 3.7.5.rc4' # this shit is very buggy don't forget to switch it off back

  # deploy
  gem 'capistrano', :require => false
  gem 'capistrano-ext', :require => false
  gem 'cape', :require => false
  # gem 'capistrano-exts', :require => false #, :git => 'git://github.com/chipiga/capistrano-exts.git'
  # gem 'capistrano-recipes', :require => false
  gem 'capistrano_colors', :require => false
end

group :development, :test do
  gem 'mysql2', '<= 0.2.9'
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
