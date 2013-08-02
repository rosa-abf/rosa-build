now = Time.now.utc
json.build_lists @build_lists do |build_list|
  json.(build_list, :id, :status, :project_id, :project_version, :save_to_platform_id, :save_to_repository_id)
  json.commit_hash build_list.commit_hash.first(5)
  json.last_published_commit_hash build_list.last_published_commit_hash.first(5) if build_list.last_published_commit_hash

  if BuildList::HUMAN_STATUSES[build_list.status].in? [:build_pending, :build_started, :build_publish]
    json.duration  Time.diff(now, build_list.updated_at, '%h:%m')[:diff]
    json.average_build_time build_list.formatted_average_build_time if build_list.build_started? && (build_list.average_build_time > 0)
  end

  json.project do
    json.name_with_owner build_list.project.name_with_owner
  end if build_list.project.present?

  json.version_release get_version_release(build_list)

  build_for = " (#{build_list.build_for_platform.name})" if build_list.build_for_platform && build_list.save_to_platform.personal?
  json.save_to_repository_name "#{build_list.save_to_platform.name}/#{build_list.save_to_repository.name}#{build_for}"

  json.arch build_list.arch.try(:name)

  json.user do
    json.fullname build_list.user.try(:fullname)
    json.uname build_list.user.uname
  end

  json.updated_at build_list.updated_at.strftime('%d/%m/%Y')
end

json.server_status  @build_server_status
json.filter         @filter.try(:options)
json.will_paginate  will_paginate(@bls).to_s.gsub(/\/build_lists.json/, '/build_lists#/build_lists').html_safe
