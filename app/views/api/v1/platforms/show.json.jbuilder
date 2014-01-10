json.platform do
  json.partial! 'platform', :platform => @platform
  json.(@platform, :description, :parent_platform_id, :released, :visibility, :platform_type, :distrib_type)
  json.created_at @platform.created_at.to_i
  json.updated_at @platform.updated_at.to_i
  json.partial! 'api/v1/shared/owner', :owner => @platform.owner
  json.repositories @platform.repositories do |repo|
    json.(repo, :id, :name)
    json.url api_v1_repository_path(repo.id, :format => :json)
  end
  json.products @platform.products do |product|
    json.partial! 'api/v1/products/product', :product => product
  end
end
