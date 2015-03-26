class ProductPolicy < ApplicationPolicy

  def index?
    record.platform.main?
  end

  def show?
    is_admin? || PlatformPolicy.new(user, record.platform).show?
  end
  alias_method :read?, :show?

  def create?
    return false unless record.platform
    is_admin? || record.platform.main? && local_admin?(record.platform)
  end
  alias_method :clone?,   :create?
  alias_method :destroy?, :create?
  alias_method :update?,  :create?

end
