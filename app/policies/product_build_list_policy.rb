class ProductBuildListPolicy < ApplicationPolicy

  def show?
    PlatformPolicy.new(user, record.platform).show?
  end
  alias_method :log?,  :show?
  alias_method :read?, :show?

  def create?
    ProjectPolicy.new(user, record.project).write? || ProductPolicy.new(user, record.product).update?
  end
  alias_method :cancel?, :create?

  def update?
    ProductPolicy.new(user, record.product).update?
  end

  def destroy?
    ProductPolicy.new(user, record.product).destroy?
  end

end
