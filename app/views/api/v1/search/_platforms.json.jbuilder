json.platforms results do |platform|
  json.partial! 'api/v1/platforms/platform', :platform => platform
end