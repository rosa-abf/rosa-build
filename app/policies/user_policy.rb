class UserPolicy < ApplicationPolicy

  def show?
    true
  end

  def update?
    is_admin? || record == user
  end

  def write?
    is_admin? || record == user
  end

  def update?
    is_admin? || record == user
  end

end
