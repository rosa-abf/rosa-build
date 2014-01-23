json.advisories @advisories do |advisory|
  json.partial! 'advisory', advisory: advisory
end
json.url api_v1_advisories_path(format: :json)