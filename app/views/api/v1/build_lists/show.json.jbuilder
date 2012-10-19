json.build_list do |json|
  json.(@build_list, :id, :name, :container_path, :status, :duration)
  json.(@build_list, :is_circle, :update_type, :build_requires, :priority)
  json.(@build_list, :advisory, :mass_build)
  json.(@build_list, :auto_publish, :package_version, :commit_hash)
  json.build_log_url log_build_list_path(@build_list)

  json.arch do |json_arch|
    json_arch.(@build_list.arch, :id, :name)
  end
  json.created_at @build_list.created_at.to_i
  json.updated_at @build_list.updated_at.to_i

  json.project do |json_project|
    json_project.(@build_list.project, :id, :name)
    json_project.fullname @build_list.project.name_with_owner
    json_project.url api_v1_project_path(@build_list.project, :format => :json)
  end

  json.save_to_repository do |json_save_to_repository|
    json_save_to_repository.(@build_list.save_to_repository, :id, :name)

    json_save_to_repository.platform do |json_str_platform|
      json_str_platform.(@build_list.save_to_repository.platform, :id, :name)
      json_str_platform.url api_v1_platform_path(@build_list.save_to_repository.platform, :format => :json)
    end

    json_save_to_repository.url api_v1_repository_path(@build_list.save_to_repository, :format => :json)
  end

  json.build_for_platform do |json_build_for_platform|
    json_build_for_platform.(@build_list.build_for_platform, :id, :name)
    json_build_for_platform.url api_v1_platform_path(@build_list.build_for_platform, :format => :json)
  end

  json.partial! 'api/v1/shared/owner', :owner => @build_list.project.owner

  inc_repos = Repository.includes(:platform).where(:id => @build_list.include_repos)
  json.include_repos inc_repos do |json_include_repos, repo|
    json_include_repos.(repo, :id, :name)
  end

  json.advisory do |json_advisory|
    json_advisory.name @build_list.advisory.advisory_id
    json_advisory.(@build_list.advisory, :description)
  end if @build_list.advisory

  json.mass_build do |json_mass_build|
    json_mass_build.(@build_list.mass_build, :id, :name)
  end if @build_list.mass_build

  json.url api_v1_build_list_path(@build_list, :format => :json)
end
