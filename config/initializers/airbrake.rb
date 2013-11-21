# -*- encoding : utf-8 -*-
require 'airbrake'

Airbrake.configure do |config|
  config.api_key = APP_CONFIG['keys']['airbrake_api_key']
  config.host    = 'errbit.rosalinux.ru'
  config.port    = 80
  config.secure  = config.port == 443
end