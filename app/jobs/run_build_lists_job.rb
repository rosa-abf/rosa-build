class RunBuildListsJob
  @queue = :middle

  def self.perform(build_list_id, user_id, project_id = nil)
    build_list  = BuildList.find(build_list_id)
    return if build_list.save_to_platform.personal?
    user        = User.find(user_id)
    ability     = Ability.new(user)

    return unless ability.can?(:show, build_list)
    project     = Project.find(project_id) if project_id.present?
    return if project && !ability.can?(:write, project)

    dependent_packages = build_list.packages.pluck(:dependent_packages).flatten.uniq
    project_ids = BuildList::Package.
      joins(:build_list).
      where(
        platform_id:  build_list.save_to_platform,
        name:         dependent_packages,
        build_lists:  { status: BuildList::BUILD_PUBLISHED }
      ).reorder(nil).uniq.pluck(:project_id)

    return if project && project_ids.exclude?(project.id)

    projects = project ? [project] : Project.where(id: project_ids).to_a

    projects.each do |project|
      next unless ability.can?(:write, project)

      build_for_platform  = save_to_platform = build_list.build_for_platform
      save_to_repository  = save_to_platform.repositories.find{ |r| r.projects.exists?(project.id) }
      next unless save_to_repository

      project_version = project.project_version_for(save_to_platform, build_for_platform)
      project.increase_release_tag(project_version, user, "BuildList##{build_list.id}: Increase release tag")

      bl                      = project.build_lists.build
      bl.save_to_repository   = save_to_repository
      bl.priority             = user.build_priority # User builds more priority than mass rebuild with zero priority
      bl.project_version      = project_version
      bl.user                 = user
      bl.include_repos        = [build_for_platform.repositories.main.first.try(:id)].compact
      bl.include_repos       |= [save_to_repository.id]
      %i(
        build_for_platform
        arch
        update_type
        save_to_platform
        auto_create_container
        extra_build_lists
        extra_params
        external_nodes
        include_testing_subrepository
        auto_publish_status
        use_cached_chroot
        use_extra_tests
        group_id
      ).each { |field| bl.send("#{field}=", build_list.send(field)) }

      ability.can?(:create, bl) && bl.save
    end
  end

end
