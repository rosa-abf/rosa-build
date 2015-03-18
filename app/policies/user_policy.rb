class UserPolicy < ApplicationPolicy

  def show?
    true
  end

  def update?
    record == user
  end

  def write?
    record == user
  end

  def update?
    record == user
  end

  def banned?
    !is_banned?
  end
end
