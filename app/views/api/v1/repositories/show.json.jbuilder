json.repository do
  json.partial! 'repository', repository: @repository
  json.(@repository, :description, :publish_without_qa)
  json.created_at @repository.created_at.to_i
  json.updated_at @repository.updated_at.to_i
  json.platform do
    json.(@repository.platform, :id, :name)
    json.url api_v1_platform_path(@repository.platform, format: :json)
  end
end