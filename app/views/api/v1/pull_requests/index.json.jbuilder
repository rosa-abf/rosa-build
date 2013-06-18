json.pulls @pulls do |json, pull|
  json.partial! 'pull', :pull => pull, :json => json
end

json.url @pulls_url
