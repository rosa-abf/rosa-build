class AdvisoryPolicy < ApplicationPolicy

  def index?
    true
  end
  alias_method :search?, :index?
  alias_method :show?, :index?

  def create?
    !user.guest?
  end
  alias_method :update?, :create?

end
