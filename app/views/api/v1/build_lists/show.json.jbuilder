json.build_list do |json|
  json.(@build_list, :id, :container_status, :status, :duration)
  json.(@build_list, :update_type, :priority, :new_core)
  json.(@build_list, :advisory, :mass_build, :use_save_to_repository)
  json.(@build_list, :auto_publish, :package_version, :commit_hash, :last_published_commit_hash, :auto_create_container)
  json.build_log_url log_build_list_path(@build_list)

  if @build_list.container_published?
    json.container_path container_url(false)
  else
    json.container_path ''
  end

  json.arch do |json_arch|
    json_arch.(@build_list.arch, :id, :name)
  end
  json.created_at @build_list.created_at.to_i
  json.updated_at @build_list.updated_at.to_i

  json.project do |json_project|
    json.partial! 'api/v1/projects/project',
      :project => @build_list.project, :json => json_project
  end

  json.save_to_repository do |json_save_to_repository|
    json.partial! 'api/v1/repositories/repository',
        :repository => @build_list.save_to_repository,
        :json => json_save_to_repository

    json_save_to_repository.platform do |json_str_platform|
      json.partial! 'api/v1/platforms/platform',
          :platform => @build_list.save_to_repository.platform,
          :json => json_str_platform
    end
  end

  json.build_for_platform do |json_build_for_platform|
    json.partial! 'api/v1/platforms/platform',
        :platform => @build_list.build_for_platform,
        :json => json_build_for_platform
  end

  json.partial! 'api/v1/shared/owner', :owner => @build_list.project.owner

  inc_repos = Repository.includes(:platform).where(:id => @build_list.include_repos)
  json.include_repos inc_repos do |json_include_repos, repo|
    json.partial! 'repositories',
      :repository => repo,
      :json => json_include_repos
  end

  extra_repos = Repository.includes(:platform).where(:id => @build_list.extra_repositories)
  json.extra_repos extra_repos do |json_extra_repos, repo|
    json.partial! 'repositories',
      :repository => repo,
      :json => json_extra_repos
  end

  extra_containers = BuildList.where(:id => @build_list.extra_containers)
  json.extra_containers extra_containers do |json_extra_containers, bl|
    json_extra_containers.(bl, :id, :status)
    json_extra_containers.container_path container_url(false, bl)
    json_extra_containers.url api_v1_build_list_path(bl, :format => :json)
  end


  json.advisory do |json_advisory|
    json_advisory.name @build_list.advisory.advisory_id
    json_advisory.(@build_list.advisory, :description)
  end if @build_list.advisory

  json.mass_build do |json_mass_build|
    json_mass_build.(@build_list.mass_build, :id, :name)
  end if @build_list.mass_build

  json.logs (@build_list.results || []) do |json_logs, result|
    json_logs.file_name result['file_name']
    json_logs.size result['size']
    json_logs.url "#{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{result['sha1']}"
  end if @build_list.new_core?

  json.packages @build_list.packages do |json_packages, package|
    json_packages.partial! 'api/v1/maintainers/package', :package => package, :json => json_packages
  end

  json.url api_v1_build_list_path(@build_list, :format => :json)
end
