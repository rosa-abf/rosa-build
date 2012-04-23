source 'http://rubygems.org'

gem 'rails', '3.2.3' #, :git => 'git://github.com/rails/rails.git'

gem 'pg', '~> 0.13.2'
# gem 'silent-postgres', :git => 'git://github.com/dolzenko/silent-postgres.git' #'~> 0.1.1'
gem 'redhillonrails_core', :git => 'git://github.com/chipiga/redhillonrails_core.git', :branch => 'rails31' # '~> 2.0.0.pre' # deprecated
# gem 'schema_plus', '~> 0.2.1' # buggy shit!

gem 'devise', '~> 2.0.4'
gem 'omniauth', '~> 1.0.3'
gem 'omniauth-openid', '~> 1.0.1'
gem 'cancan', '~> 1.6.7'

gem 'ancestry', '~> 1.2.5'
gem 'paperclip', '~> 3.0.2'
gem 'delayed_job_active_record', '~> 0.3.2'
gem 'russian', '~> 0.6.0'
gem 'highline', '~> 1.6.11'

gem 'jbuilder'

# gem 'rugged', '~> 0.16.0'
gem 'grack', :git => 'git://github.com/rdblue/grack.git', :require => 'git_http'
gem "grit", :git => 'git://github.com/warpc/grit.git' #, :path => '~/Sites/code/grit'
gem 'charlock_holmes', '~> 0.6.8' #, :git => 'git://github.com/brianmario/charlock_holmes.git', :branch => 'bundle-icu'
gem 'diff-display', '~> 0.0.1'

# Wiki
gem "gollum", "1.3.1"
gem "redcarpet", "1.17.2"
gem 'creole'
gem 'rdiscount'
# gem 'org-ruby'
gem 'RedCloth'
gem 'wikicloth'

gem 'unicorn', '~> 4.2.1', :platforms => [:mri, :rbx]
gem 'trinidad', '~> 1.0.2', :platforms => :jruby
gem 'newrelic_rpm', '~> 3.3.3', :platforms => [:mri, :rbx]
gem 'whenever', '~> 0.7.3', :require => false

gem 'rails3-jquery-autocomplete', '~> 1.0.7'
gem 'will_paginate', '~> 3.0.3'
gem 'meta-tags', '~> 1.2.5', :require => 'meta_tags'
gem "haml-rails", '~> 0.3.4'
gem 'jquery-rails', '~> 2.0.2'
gem 'ruby-haml-js', '~> 0.0.3'
gem 'rails-backbone', '~> 0.7.2'

group :assets do
  gem 'sass-rails', '~> 3.2.5'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'compass-rails', '~> 1.0.1'
  gem 'uglifier', '~> 1.2.4'
  gem 'therubyracer', '~> 0.10.1', :platforms => [:mri, :rbx]
  gem 'therubyrhino', '~> 1.73.1', :platforms => :jruby
end

group :production do
  gem "airbrake", '~> 3.0.9'
  gem 'bluepill', '~> 0.0.60', :require => false
  gem 'daemons', '1.1.6' # Try to upgrade 1.1.8 to avoid tons DJ bugs?
end

group :development do
  gem 'mailcatcher' # 'letter_opener'
  gem 'rails3-generators'
  gem 'hirb'
  gem 'shotgun'
  # deploy
  gem 'capistrano', :require => false
  gem 'cape', :require => false
  gem 'capistrano_colors', :require => false
end

group :test do
  gem 'rspec-rails',        '~> 2.9.0', :group => 'development'
  gem 'factory_girl_rails', '~> 3.1.0'
  gem 'rr',                 '~> 1.0.4'
  gem 'shoulda'
end
