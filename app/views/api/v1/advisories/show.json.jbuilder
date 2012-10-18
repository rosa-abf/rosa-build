json.advisory do |json|
  json.partial! 'advisory', :advisory => @advisory, :json => json
  json.created_at @advisory.created_at.to_i
  json.updated_at @advisory.updated_at.to_i
  json.build_lists @advisory.build_lists do |json_build_list, build_list|
    json_build_list.(build_list, :id)
    json_build_list.url api_v1_build_list_path(build_list.id, :format => :json)
  end

  json.affected_in @packages_info do |json_platform, package_info|
    platform = package_info[0]
    json_platform.(platform, :id)
    json_platform.url api_v1_platform_path(platform.id, :format => :json)
    json_platform.projects package_info[1] do |json_project, info|
      project = info[0]
      json_project.(project, :id)
      json_project.url api_v1_project_path(project.id, :format => :json)
      packages = info[1]
      json_project.srpm packages[:srpm]
      json_project.rpm packages[:rpm]
    end
  end

end
