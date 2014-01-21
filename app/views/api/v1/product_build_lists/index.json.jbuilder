json.product_build_lists @product_build_lists do |json, product_build_list|
  json.partial! 'product_build_list', product_build_list: product_build_list, json: json
end

json.url api_v1_product_build_lists_path(format: :json)

