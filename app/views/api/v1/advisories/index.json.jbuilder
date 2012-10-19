json.advisories @advisories do |json, advisory|
  json.partial! 'advisory', :advisory => advisory, :json => json
end
json.url api_v1_advisories_path(:format => :json)