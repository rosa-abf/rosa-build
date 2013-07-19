json.advisory do
  json.partial! 'advisory', :advisory => @advisory
  json.created_at @advisory.created_at.to_i
  json.updated_at @advisory.updated_at.to_i
  json.(@advisory, :update_type)
  json.references @advisory.references.split('\n')
  
  json.build_lists @advisory.build_lists do |build_list|
    json.(build_list, :id)
    json.url api_v1_build_list_path(build_list.id, :format => :json)
  end

  json.affected_in @packages_info do |package_info|
    json.partial! 'api/v1/platforms/platform', :platform => package_info[0]

    json.projects package_info[1] do |info|
      json.partial! 'api/v1/projects/project', :project => info[0]
        
      packages = info[1]
      json.srpm packages[:srpm]
      json.rpm packages[:rpm]
    end
  end

end
