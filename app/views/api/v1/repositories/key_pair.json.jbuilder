json.repository do |json|
  json.partial! 'repository', :repository => @repository, :json => json
  json.key_pair do |json_key_pair|
    json_key_pair.(@repository.key_pair, :public, :secret)
  end
end