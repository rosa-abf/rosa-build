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
    local_reader?
  end

  def write?
    owner? || local_writer?
  end

  def update?
    owner? || local_admin?
  end
  alias_method :manage_members?, :update?
  alias_method :remove_members?, :update?
  alias_method :add_member?, :update?

end
