class MassBuildPolicy < ApplicationPolicy

  def show?
    is_admin? || PlatformPolicy.new(user, record.save_to_platform).show?
  end
  alias_method :read?,       :show?
  alias_method :get_list?,   :show?
  alias_method :show_fail_reason?, :show?
  def create?
    is_admin? || owner?(record.save_to_platform) || local_admin?(record.save_to_platform)
  end
  alias_method :publish?, :create?

  def cancel?
    !record.stop_build && create?
  end

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(
      arches
      auto_create_container
      auto_publish_status
      build_for_platform_id
      description
      external_nodes
      include_testing_subrepository
      increase_release_tag
      projects_list
      repositories
      use_cached_chroot
      use_extra_tests
    ) << {
      extra_build_lists:  [],
      extra_mass_builds:  [],
      extra_repositories: []
    }
  end

end
