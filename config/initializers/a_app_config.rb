APP_CONFIG = YAML.load_file("#{Rails.root}/config/application.yml")[Rails.env]
# Remove '/' from the end of url
APP_CONFIG.keys.select {|key| key =~ /_url\Z/}.each {|key| APP_CONFIG[key] = APP_CONFIG[key].chomp('/') if APP_CONFIG[key].respond_to?(:chomp)}
# Paginates a static array
require 'will_paginate/array'
