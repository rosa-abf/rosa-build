json.product_build_list do
  json.(@product_build_list, :id, :status, :human_status)
  json.notified_at l(@product_build_list.updated_at, format: :long)

  json.not_delete   @product_build_list.not_delete?.to_s
  json.can_cancel   @product_build_list.can_cancel?
  json.can_destroy  @product_build_list.can_destroy?

  json.results @product_build_list.results do |result|
    json.file_name result['file_name']
    json.sha1 result['sha1']
    json.size result['size']

    timestamp = result['timestamp']
    json.created_at Time.zone.at(result['timestamp']).to_s if timestamp

    json.url file_store_results_url(result['sha1'], result['file_name'])
  end if @product_build_list.results.present?

end
