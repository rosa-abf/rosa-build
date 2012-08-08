json.build_list do |json|
  json.(@build_list, :id, :bs_id, :name, :container_path, :status, :project_version, :project_id)
  json.project_name @build_list.project.name
  json.(@build_list, :build_for_platform_id, :save_to_platform_id)
  json.build_for_platform_name @build_list.build_for_platform.name
  json.save_to_platform_name @build_list.save_to_platform.name
  json.(@build_list, :notified_at, :is_circle, :update_type, :build_requires, :auto_publish, :package_version, :commit_hash, :duration, :mass_build_id, :advisory_id)
  json.arch_name @build_list.arch.name
  json.user do |json_user|
    json_user.(@build_list.user, :id, :name)
    json_user.url user_path(@build_list.user)
  end
  json.additional_repos @build_list.additional_repos do |json_repos, repo|
    json_repos.(repo, :id, :name)
  end if @build_list.additional_repos
  json.url api_v1_build_list_path(@build_list, :format => :json)
end
