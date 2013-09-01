now = Time.now.utc
json.build_lists @build_lists do |build_list|
  json.(build_list, :id, :status, :project_id, :project_version, :save_to_platform_id, :save_to_repository_id, :user_id, :project_id, :build_for_platform_id, :arch_id)
  json.commit_hash build_list.commit_hash.first(5)
  json.last_published_commit_hash build_list.last_published_commit_hash.first(5) if build_list.last_published_commit_hash

  if BuildList::HUMAN_STATUSES[build_list.status].in? [:build_pending, :build_started, :build_publish]
    json.duration  Time.diff(now, build_list.updated_at, '%h:%m')[:diff]
    json.average_build_time build_list.formatted_average_build_time if build_list.build_started? && (build_list.average_build_time > 0)
  end

  json.version_release get_version_release(build_list)
  json.updated_at build_list.updated_at
  json.updated_at_utc build_list.updated_at.strftime('%Y-%m-%d %H:%M:%S UTC')
end

json.dictionary  do
  json.users @build_lists.map(&:user).uniq do |user|
    json.(user, :id, :uname, :fullname)
  end
  json.projects @build_lists.map(&:project).uniq.compact do |project|
    json.(project, :id, :name)
    json.owner project.name_with_owner.gsub(/\/.*/, '')
  end
  json.platforms (@build_lists.map(&:build_for_platform) | @build_lists.map(&:save_to_platform)).uniq do |platform|
    json.(platform, :id, :name)
    json.personal platform.personal?
  end
  json.repositories @build_lists.map(&:save_to_repository).uniq do |repository|
    json.(repository, :id, :name)
  end
  json.arches Arch.all do |arch|
    json.(arch, :id, :name)
  end
end

json.server_status  @build_server_status
json.filter         @filter.try(:options)
json.pages          angularjs_will_paginate(@bls)
