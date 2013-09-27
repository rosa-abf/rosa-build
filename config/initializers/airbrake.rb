# -*- encoding : utf-8 -*-
require 'airbrake'

Airbrake.configure do |config|
  config.api_key  = APP_CONFIG['keys']['airbrake_api_key']
  config.host     = 'api.rollbar.com'
  config.secure   = true
end