require 'le'

key = APP_CONFIG['keys']['logentries_key']
if Rails.env.development?
  Rails.logger = Le.new key, :debug => true
else
  Rails.logger = Le.new key
end