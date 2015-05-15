module BuildLists
  class DependentPackagesJob
    @queue = :middle

    def self.perform(build_list_id, user_id, project_ids, arch_ids, options)
      build_list  = BuildList.find(build_list_id)
      return if build_list.save_to_platform.personal?
      user        = User.find(user_id)

      return unless BuildListPolicy.new(user, build_list).show?

      arches = Arch.where(id: arch_ids).to_a
      Project.where(id: project_ids).to_a.each do |project|
        next unless ProjectPolicy.new(user, project).write?

        build_for_platform  = save_to_platform = build_list.build_for_platform
        save_to_repository  = save_to_platform.repositories.find{ |r| r.projects.exists?(project.id) }
        next unless save_to_repository

        project_version = project.project_version_for(save_to_platform, build_for_platform)
        project.increase_release_tag(project_version, user, "BuildList##{build_list.id}: Increase release tag")

        arches.each do |arch|
          bl                      = project.build_lists.build
          bl.arch                 = arch
          bl.save_to_repository   = save_to_repository
          bl.priority             = user.build_priority # User builds more priority than mass rebuild with zero priority
          bl.project_version      = project_version
          bl.user                 = user
          bl.include_repos        = [build_for_platform.repositories.main.first.try(:id)].compact
          bl.include_repos       |= [save_to_repository.id]
          %i(
            build_for_platform
            update_type
            save_to_platform
            extra_build_lists
            extra_params
            external_nodes
            group_id
          ).each { |field| bl.send("#{field}=", build_list.send(field)) }

          bl.auto_publish_status = options[:auto_publish_status]
          %i(
            auto_create_container
            include_testing_subrepository
            use_cached_chroot
            use_extra_tests
          ).each { |field| bl[field] = options[field] == '1' }

          # debug
          if BuildListPolicy.new(user, bl).create?
            begin
              bl.save!
            rescue ActiveRecord::RecordInvalid => invalid
              raise 'DEBUG: ' + invalid.record.errors.full_messages.join('; ')
            end
          else
            raise 'DEBUG: BuildListPolicy.new(user, bl).create? is false!'
          end
        end
      end
    end

  end
end