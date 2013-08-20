json.product_build_list do
  json.(@product_build_list, :id, :status, :human_status, :not_delete)
  json.notified_at l(@product_build_list.updated_at, :format => :long)

  json.can_cancel @product_build_list.can_cancel?

  json.results @product_build_list.results do |result|
    json.file_name result['file_name']
    json.sha1 result['sha1']
    json.size result['size']
    json.url "#{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{result['sha1']}"
  end if @product_build_list.results.present?

end
