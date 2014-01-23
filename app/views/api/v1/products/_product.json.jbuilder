json.(product, :id, :name, :description, :main_script, :params, :time_living, :autostart_status)
json.url api_v1_product_path(product, format: :json)

