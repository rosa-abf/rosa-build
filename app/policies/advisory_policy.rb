class AdvisoryPolicy < ApplicationPolicy

  def index?
    true
  end
  alias_method :search?, :index?
  alias_method :show?, :index?

end
