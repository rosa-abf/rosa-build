class UserPolicy < ApplicationPolicy

  def show?
    true
  end

  def update?
    is_admin? || record == user
  end
  alias_method :notifiers?,         :update?
  alias_method :show_current_user?, :update?
  alias_method :write?,             :update?

  class Scope < Scope
    def show
      scope
    end
  end

end
