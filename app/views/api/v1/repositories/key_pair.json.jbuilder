json.repository do |json|
  json.partial! 'repository', :repository => @repository, :json => json
  json.key_pair do |json_key_pair|
    if @repository.key_pair
      json_key_pair.(@repository.key_pair, :public, :secret)
    else
      json_key_pair.public ''
      json_key_pair.secret ''
    end
  end
end