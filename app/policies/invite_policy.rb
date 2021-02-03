class InvitePolicy < ApplicationPolicy
  def invites?
    is_user?
  end

  def create_invite?
    is_user?
  end
end