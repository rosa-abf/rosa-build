json.repository do |json|
  json.(@repository, :id, :name, :description, :publish_without_qa)
  json.created_at @repository.created_at.to_i
  json.updated_at @repository.updated_at.to_i
  json.platform do |json_platform|
    json_platform.(@repository.platform, :id, :name)
    json_platform.url api_v1_platform_path(@repository.platform, :format => :json)
  end
end

json.url api_v1_repository_path(@repository, :format => :json)
