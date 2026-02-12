APP_CONFIG = YAML.unsafe_load(ERB.new(File.read("#{Rails.root}/config/application.yml")).result)[Rails.env] # FIXME upgrade
# Remove '/' from the end of url
APP_CONFIG.keys.select {|key| key =~ /_url\Z/}.each {|key| APP_CONFIG[key] = APP_CONFIG[key].chomp('/') if APP_CONFIG[key].respond_to?(:chomp)}
# Paginates a static array
require 'will_paginate/array'
