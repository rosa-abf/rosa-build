now = Time.now.utc
json.build_lists @build_lists do |build_list|
  json.(build_list, :id, :status, :human_status)
  json.url build_list_path(build_list)

  if BuildList::HUMAN_STATUSES[build_list.status].in? [:build_pending, :build_started, :build_publish]
    json.duration  Time.diff(now, build_list.updated_at, '%h:%m')[:diff]
    json.average_build_time build_list.formatted_average_build_time if build_list.build_started? && (build_list.average_build_time > 0)
  end
  json.status_color build_list_status_color(build_list.status)

  json.project do
    json.name_with_owner build_list.project.name_with_owner
    json.url project_path(build_list.project)
    json.version_link build_list_version_link(build_list).html_safe
  end if build_list.project.present?

  json.project_version get_version_release(build_list)

  json.save_to_repository do
    build_for = " (#{build_list.build_for_platform.name})" if build_list.build_for_platform && build_list.save_to_platform.personal?
    
    json.name "#{build_list.save_to_platform.name}/#{build_list.save_to_repository.name}#{build_for}"

    json.url platform_repository_path(build_list.save_to_platform, build_list.save_to_repository)
  end

  json.arch build_list.arch.try(:name)

  json.user do
    json.fullname build_list.user.try(:fullname)
    json.url user_path(build_list.user)
  end

  json.updated_at build_list.updated_at.strftime('%d/%m/%Y')
end

json.server_status  @build_server_status
json.filter  @filter.try(:options)
