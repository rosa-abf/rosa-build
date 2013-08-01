build_lists = @build_lists.map do |build_list|
  build_for = " (#{build_list.build_for_platform.name})" if build_list.build_for_platform && build_list.save_to_platform.personal?
  [
    [link_to(build_list.id, build_list),
     link_to(t('layout.clone'), new_project_build_list_path(@project, :build_list_id => build_list.id))
    ].join('<br/>').html_safe,
    build_list.human_status,
    build_list_version_link(build_list),
    get_version_release(build_list),
    link_to("#{build_list.save_to_platform.name}/#{build_list.save_to_repository.name}#{build_for}", [build_list.save_to_platform, build_list.save_to_repository]),
    build_list.arch.try(:name) || t('layout.arches.unexisted_arch'),
    link_to(build_list.user.try(:fullname), build_list.user),
    build_list.updated_at.strftime('%d/%m/%Y')
  ]
end

json.sEcho                params[:sEcho].to_i || -1
json.iTotalRecords        @total_build_lists
json.iTotalDisplayRecords @build_lists.count
json.aaData               build_lists
