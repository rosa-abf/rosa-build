json.build_lists @build_lists do |build_list|
  json.(build_list, :id, :status, :project_id)
  json.url api_v1_build_list_path(build_list, format: :json)
end

json.url api_v1_build_lists_path(format: :json, params: {filter: params[:filter] } )

