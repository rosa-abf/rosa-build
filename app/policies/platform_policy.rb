class PlatformPolicy < ApplicationPolicy

  def index?
    !user.guest?
  end

  def show?
    return true unless record.hidden?
    return true if record.owner == user
    owner? || local_reader? || user_platform_ids.include?(record.id)
  end
  alias_method :advisories?, :show?
  alias_method :members?,    :show?
  alias_method :owned?,      :show?
  alias_method :read?,       :show?
  alias_method :related?,    :show?

  def platforms_for_build?
    true
  end

  def create?
    is_admin?
  end

  def update?
    owner?
  end
  alias_method :change_visibility?, :update?

  def destroy?
    record.main? && owner?
  end

  def local_admin_manage?
    owner? || local_admin?
  end
  alias_method :add_project?,         :local_admin_manage?
  alias_method :remove_file?,         :local_admin_manage?

  def clone?
    record.main? && ( owner? || local_admin? )
  end
  alias_method :add_member?,          :clone?
  alias_method :members?,             :clone?
  alias_method :regenerate_metadata?, :clone?
  alias_method :remove_member?,       :clone?
  alias_method :remove_members?,      :clone?

  def clear?
    record.personal? && owner?
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
