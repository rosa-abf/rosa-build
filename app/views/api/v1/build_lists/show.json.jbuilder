json.build_list do
  json.(@build_list, :id, :container_status, :status, :duration)
  json.(@build_list, :update_type, :priority, :new_core)
  json.(@build_list, :advisory, :mass_build)
  json.(@build_list, :auto_publish, :package_version, :commit_hash, :last_published_commit_hash, :auto_create_container)
  json.build_log_url log_build_list_path(@build_list)

  if @build_list.container_published?
    json.container_path container_url
  else
    json.container_path ''
  end

  json.arch do
    json.(@build_list.arch, :id, :name)
  end
  json.created_at @build_list.created_at.to_i
  json.updated_at @build_list.updated_at.to_i

  json.project do
    json.partial! 'api/v1/projects/project', project: @build_list.project
  end

  json.save_to_repository do
    json.partial! 'api/v1/repositories/repository',
        repository: @build_list.save_to_repository

    json.platform do
      json.partial! 'api/v1/platforms/platform',
          platform: @build_list.save_to_repository.platform
    end
  end

  json.build_for_platform do
    json.partial! 'api/v1/platforms/platform',
        platform: @build_list.build_for_platform
  end

  json.user do
    json.partial! 'api/v1/shared/member', member: @build_list.user
  end

  json.publisher do
    json.partial! 'api/v1/shared/member', member: @build_list.publisher
  end if @build_list.publisher

  inc_repos = Repository.includes(:platform).where(id: @build_list.include_repos)
  json.include_repos inc_repos do |repo|
    json.partial! 'repositories', repository: repo
  end

  extra_repos = Repository.includes(:platform).where(id: @build_list.extra_repositories)
  json.extra_repositories extra_repos do |repo|
    json.partial! 'repositories', repository: repo
  end

  extra_build_lists = BuildList.where(id: @build_list.extra_build_lists)
  json.extra_build_lists extra_build_lists do |bl|
    json.(bl, :id, :status)
    json.container_path container_url(bl)
    json.url api_v1_build_list_path(bl, format: :json)
  end

  json.extra_params @build_list.extra_params

  json.advisory do
    json.name @build_list.advisory.advisory_id
    json.(@build_list.advisory, :description)
  end if @build_list.advisory

  json.mass_build do
    json.(@build_list.mass_build, :id, :name)
  end if @build_list.mass_build

  json.logs (@build_list.results || []) do |result|
    json.file_name result['file_name']
    json.size result['size']
    json.url "#{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{result['sha1']}"
  end if @build_list.new_core?

  json.packages @build_list.packages do |package|
    json.partial! 'api/v1/maintainers/package', package: package
  end

  json.url api_v1_build_list_path(@build_list, format: :json)
end
