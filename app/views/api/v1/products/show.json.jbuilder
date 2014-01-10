json.product do
  json.partial! 'product', :product => @product
  json.platform do
    json.partial! 'api/v1/platforms/platform', :platform => @product.platform
  end
  if @product.project.present?
    json.project do
      json.partial! 'api/v1/projects/project', :project => @product.project
    end
  end
  json.created_at @product.created_at.to_i
  json.updated_at @product.updated_at.to_i
end
