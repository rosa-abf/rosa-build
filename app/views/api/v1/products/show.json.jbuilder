json.product do |json|
  json.partial! 'product', :product => @product, :json => json
  json.platform do |json_platform|
    json.partial! 'api/v1/platforms/platform', :platform => @product.platform, :json => json_platform
  end
  if @product.project.present?
    json.project do |json_project|
      json.partial! 'api/v1/projects/project', :project => @product.project, :json => json_project
    end
  end
  json.created_at @product.created_at.to_i
  json.updated_at @product.updated_at.to_i
end
