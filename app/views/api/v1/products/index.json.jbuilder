json.platform do |json_platform|
  json.partial! 'api/v1/platforms/platform', :platform => @platform, :json => json_platform
end

json.products @products do |json, product|
  json.partial! 'product', :product => product, :json => json
end

json.url api_v1_products_path(@platform.id, :format => :json)
