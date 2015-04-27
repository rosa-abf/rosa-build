class BuildListPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    record.user_id == user.id || ProjectPolicy.new(user, record.project).show?
  end
  alias_method :read?,       :show?
  alias_method :log?,        :show?
  alias_method :everything?, :show?
  alias_method :owned?,      :show?
  alias_method :everything?, :show?
  alias_method :list?,       :show?

  def create?
    return false unless record.project.is_package
    return false unless ProjectPolicy.new(user, record.project).write?
    record.build_for_platform.blank? || PlatformPolicy.new(user, record.build_for_platform).show?
  end
  alias_method :rerun_tests?, :create?

  def dependent_projects?
    record.save_to_platform.main? && create?
  end

  def publish_into_testing?
    return false unless record.new_core?
    return false unless record.can_publish_into_testing?
    create? || ( record.save_to_platform.main? && publish? )
  end

  def publish?
    return false unless record.new_core?
    return false unless record.can_publish?
    if record.build_published?
      local_admin?(record.save_to_platform) || record.save_to_repository.members.exists?(id: user.id)
    else
      record.save_to_repository.publish_without_qa ?
      ProjectPolicy.new(user, record.project).write? : local_admin?(record.save_to_platform)
    end
  end
  alias_method :update_type?, :publish?

  def create_container?
    return false unless record.new_core?
    ProjectPolicy.new(user, record.project).write? || local_admin?(record.save_to_platform)
  end

  def reject_publish?
    record.save_to_repository.publish_without_qa ?
    ProjectPolicy.new(user, record.project).write? : local_admin?(record.save_to_platform)
  end

  def cancel?
    ProjectPolicy.new(user, record.project).write?
  end

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(
      arch_id
      auto_create_container
      auto_publish
      auto_publish_status
      build_for_platform_id
      commit_hash
      external_nodes
      extra_build_lists
      extra_params
      extra_repositories
      include_repos
      include_testing_subrepository
      project_id
      project_version
      save_buildroot
      save_to_platform_id
      save_to_repository_id
      update_type,
      use_cached_chroot
      use_extra_tests
    )
  end

  class Scope < Scope

    def read
      scope.joins(:project).where <<-SQL, { user_id: policy.user.id, user_group_ids: policy.user_group_ids }
        (
          build_lists.user_id = :user_id
        ) OR (
          projects.visibility = 'open'
        ) OR (
          projects.owner_type = 'User'  AND projects.owner_id = :user_id
        ) OR (
          projects.owner_type = 'Group' AND projects.owner_id IN (:user_group_ids)
        ) OR (
          projects.id = ANY (
            ARRAY (
              SELECT target_id
              FROM relations
              INNER JOIN projects ON projects.id = relations.target_id
              WHERE relations.target_type = 'Project' AND
              (
                projects.owner_type = 'User' AND projects.owner_id != :user_id OR
                projects.owner_type = 'Group' AND projects.owner_id NOT IN (:user_group_ids)
              ) AND (
                relations.actor_type = 'User' AND relations.actor_id = :user_id OR
                relations.actor_type = 'Group' AND relations.actor_id IN (:user_group_ids)
              )
            )
          )
        )
      SQL
    end
    alias_method :everything, :read

    def related
      scope.joins(:project).where <<-SQL, { user_id: policy.user.id, user_group_ids: policy.user_group_ids }
        (
          build_lists.user_id = :user_id
        ) OR (
          projects.owner_type = 'User'  AND projects.owner_id = :user_id
        ) OR (
          projects.owner_type = 'Group' AND projects.owner_id IN (:user_group_ids)
        ) OR (
          projects.id = ANY (
            ARRAY (
              SELECT target_id
              FROM relations
              INNER JOIN projects ON projects.id = relations.target_id
              WHERE relations.target_type = 'Project' AND
              (
                projects.owner_type = 'User' AND projects.owner_id != :user_id OR
                projects.owner_type = 'Group' AND projects.owner_id NOT IN (:user_group_ids)
              ) AND (
                relations.actor_type = 'User' AND relations.actor_id = :user_id OR
                relations.actor_type = 'Group' AND relations.actor_id IN (:user_group_ids)
              )
            )
          )
        )
      SQL
    end

    def owned
      scope.joins(:project).where(user_id: policy.user)
    end

    def policy
      @policy ||= Pundit.policy!(user, :build_list)
    end
  end

end
