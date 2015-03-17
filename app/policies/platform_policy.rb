class PlatformPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    return true unless record.hidden?
    return true if record.owner == user
    return true if owner?
  end

  def create?
    is_admin?
  end

  def update?
    owner?
  end

  def local_admin_manage?
    owner? || local_admin?
  end
  alias_method :add_project?, :local_admin_manage?

  def clone?
    return false if record.personal?
    owner? || local_admin?
  end

  class Scope < Scope

    def related
      policy = Pundit.policy!(user, :platform)
      scope.where <<-SQL, { user_id: user.id, user_group_ids: policy.user_group_ids, platform_ids: related_platform_ids }
        (
          platforms.id IN (:platform_ids)
        ) OR (
          platforms.owner_type = 'User'  AND platforms.owner_id = :user_id
        ) OR (
          platforms.owner_type = 'Group' AND platforms.owner_id IN (:user_group_ids)
        )
      SQL
    end

    protected

    def related_platform_ids
      Rails.cache.fetch(['PlatformPolicy::Scope#related_platform_ids', user]) do
        user.repositories.pluck(:platform_id)
      end
    end
  end

end
