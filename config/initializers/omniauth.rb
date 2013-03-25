# require "omniauth-facebook"

# Rails.application.config.middleware.use OmniAuth::Builder do
#   [:facebook, :github, :google_oauth2].each do |kind|
#     provider kind, APP_CONFIG['keys']["#{kind}"]['id'], APP_CONFIG['keys']["#{kind}"]['secret']
#   end
# end

OmniAuth.config.logger = Rails.logger