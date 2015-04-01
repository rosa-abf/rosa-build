class GroupPolicy < ApplicationPolicy

  def index?
    !user.guest?
  end

  def show?
    true
  end

  def create?
    !user.guest?
  end

  def reader?
    is_admin? || local_reader?
  end

  def write?
    is_admin? || owner? || local_writer?
  end

  def update?
    is_admin? || owner? || local_admin?
  end
  alias_method :add_member?,      :update?
  alias_method :manage_members?,  :update?
  alias_method :members?,         :update?
  alias_method :remove_member?,   :update?
  alias_method :remove_members?,  :update?
  alias_method :remove_user?,     :update?
  alias_method :update_member?,   :update?

  def destroy?
    is_admin? || owner?
  end

  def remove_user?
    !user.guest?
  end

  class Scope < Scope
    def show
      scope
    end
  end

end
