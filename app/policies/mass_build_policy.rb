class MassBuildPolicy < ApplicationPolicy

  def show?
    policy(record.save_to_platform).show?
  end
  alias_method :read?,       :show?
  alias_method :get_list?,   :show?

  def create?
    owner?(record.save_to_platform) || local_admin?(record.save_to_platform)
  end
  alias_method :publish?, :create?

  def cancel?
    !record.stop_build && create?
  end

end
