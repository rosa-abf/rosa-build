class PlatformPolicy < ApplicationPolicy

  def index?
    !user.guest?
  end

  def allowed?
    true
  end
  alias_method :platforms_for_build?, :allowed?

  def show?
    return true if is_admin?
    return true unless record.hidden?
    return true if record.owner == user
    owner? || local_reader? || user_platform_ids.include?(record.id)
  end
  alias_method :advisories?, :show?
  alias_method :owned?,      :show?
  alias_method :read?,       :show?
  alias_method :related?,    :show?

  def members?
    return true if is_admin?
    return true unless record.hidden?
    return true if record.owner == user
    owner? || local_reader?
  end

  def create?
    is_admin?
  end

  def update?
    is_admin? || owner?
  end
  alias_method :change_visibility?, :update?

  def destroy?
    record.main? && ( is_admin? || owner? )
  end

  def local_admin_manage?
    is_admin? || owner? || local_admin?
  end
  alias_method :add_project?,         :local_admin_manage?
  alias_method :remove_file?,         :local_admin_manage?

  def clone?
    record.main? && is_admin?
  end
  alias_method :make_clone?, :clone?

  def add_member?
    record.main? && ( is_admin? || owner? || local_admin? )
  end
  alias_method :regenerate_metadata?, :add_member?
  alias_method :remove_member?,       :add_member?
  alias_method :remove_members?,      :add_member?

  def clear?
    record.personal? && ( is_admin? || owner? )
  end

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(
      admin_id
      automatic_metadata_regeneration
      default_branch
      description
      distrib_type
      name
      owner
      parent_platform_id
      platform_arch_settings_attributes
      platform_type
      released
      term
      visibility
    )
  end

  class Scope < Scope

    def related
      scope.where <<-SQL, { user_id: policy.user.id, user_group_ids: policy.user_group_ids, platform_ids: related_platform_ids }
        (
          platforms.id IN (:platform_ids)
        ) OR (
          platforms.owner_type = 'User'  AND platforms.owner_id = :user_id
        ) OR (
          platforms.owner_type = 'Group' AND platforms.owner_id IN (:user_group_ids)
        ) OR (
          platforms.id = ANY (
            ARRAY (
              SELECT target_id
              FROM relations
              INNER JOIN platforms ON platforms.id = relations.target_id
              WHERE relations.target_type = 'Platform' AND
              (
                platforms.owner_type = 'User' AND platforms.owner_id != :user_id
              ) AND (
                relations.actor_type = 'User' AND relations.actor_id = :user_id
              )
            )
          )
        )
      SQL
    end

    def show
      scope.where <<-SQL, { user_id: policy.user.id, user_group_ids: policy.user_group_ids, platform_ids: related_platform_ids, visibility: Platform::VISIBILITY_OPEN }
        (
          platforms.visibility = :visibility
        ) OR (
          platforms.id IN (:platform_ids)
        ) OR (
          platforms.owner_type = 'User'  AND platforms.owner_id = :user_id
        ) OR (
          platforms.owner_type = 'Group' AND platforms.owner_id IN (:user_group_ids)
        ) OR (
          platforms.id = ANY (
            ARRAY (
              SELECT target_id
              FROM relations
              INNER JOIN platforms ON platforms.id = relations.target_id
              WHERE relations.target_type = 'Platform' AND
              (
                platforms.owner_type = 'User' AND platforms.owner_id != :user_id
              ) AND (
                relations.actor_type = 'User' AND relations.actor_id = :user_id
              )
            )
          )
        )
      SQL
    end

    protected

    def policy
      @policy ||= Pundit.policy!(user, :platform)
    end

    def related_platform_ids
      Rails.cache.fetch(['PlatformPolicy::Scope#related_platform_ids', policy.user]) do
        policy.user.repositories.pluck(:platform_id)
      end
    end
  end

end
