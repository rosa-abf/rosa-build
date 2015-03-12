class UserPolicy < ApplicationPolicy

  def banned?
    !is_banned?
  end
end
