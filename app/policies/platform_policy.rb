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

  def members?
    owner? || local_admin?
  end

  def clone?
    return false if record.personal?
    owner? || local_admin?
  end

  class Scope < Scope

    def related
      scope.where <<-SQL, { user_id: user.id, user_group_ids: user_group_ids, platform_ids: related_platform_ids }
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
      Rails.cache.fetch(['PlatformPolicy::Scope#related_platform_ids', user.id]) do
        user.repositories.pluck(:platform_id)
      end
    end
  end

  protected

  def owner?
    record.owner == user ||
    record.owner.is_a?(Group) && user_group_ids.include?(record.owner_id)
  end

  def local_admin?
    Rails.cache.fetch(['PlatformPolicy#local_admin?', record, user]) do
      user.best_role(record) == 'admin'
    end
  end

end
