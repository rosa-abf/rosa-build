class MassBuildPolicy < ApplicationPolicy

  def show?
    is_admin? || PlatformPolicy.new(user, record.save_to_platform).show?
  end
  alias_method :read?,       :show?
  alias_method :get_list?,   :show?

  def create?
    is_admin? || owner?(record.save_to_platform) || local_admin?(record.save_to_platform)
  end
  alias_method :publish?, :create?

  def cancel?
    !record.stop_build && create?
  end

end
