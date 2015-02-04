json.build_lists @build_lists do |bl|
  json.id           bl.id
  json.path         build_list_path(bl)
  json.human_status bl.human_status

  json.version do
    json.name    build_list_version_name(bl)
    json.path    get_build_list_version_path(bl)
    json.release get_version_release(bl)
  end

  if bl.build_for_platform && bl.save_to_platform.personal?
    build_for = " (#{bl.build_for_platform.name})"
  end

  json.save_to_repository do
    json.path platform_repository_path(bl.save_to_platform, bl.save_to_repository)
    json.name "#{bl.save_to_platform.name}/#{bl.save_to_repository.name}#{build_for}"
  end

  json.arch bl.arch.try(:name) || t('layout.arches.unexisted_arch')
  json.user do
    json.path     user_path(bl.user) if bl.user
    json.fullname bl.user.try(:fullname)
  end

  json.updated_at bl.updated_at
end

json.total_items @total_build_lists
