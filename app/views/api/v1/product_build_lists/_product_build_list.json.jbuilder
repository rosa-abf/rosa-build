json.(product_build_list, :id, :status, :time_living)
json.notified_at product_build_list.updated_at
json.url api_v1_product_build_list_path(product_build_list, format: :json)

