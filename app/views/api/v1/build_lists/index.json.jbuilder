json.build_lists @build_lists do |json, build_list|
  json.(build_list, :id, :bs_id, :name, :status)
  json.url api_v1_build_list_path(build_list, :format => :json)
end

json.url api_v1_build_lists_path(:format => :json)
