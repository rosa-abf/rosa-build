json.repository do
  json.partial! 'repository', :repository => @repository
  json.key_pair do
    if @repository.key_pair
      json.(@repository.key_pair, :public, :secret)
    else
      json.public ''
      json.secret ''
    end
  end
end