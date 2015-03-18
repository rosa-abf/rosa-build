class ProductBuildListPolicy < ApplicationPolicy

  def show?
    policy(record.platform).show?
  end
  alias_method :log?,  :show?
  alias_method :read?, :show?

  def create?
    policy(record.project).write? || policy(record.product).update?
  end
  alias_method :cancel?, :create?

  def update?
    policy(record.product).update?
  end

  def destroy?
    policy(record.product).destroy?
  end

end
