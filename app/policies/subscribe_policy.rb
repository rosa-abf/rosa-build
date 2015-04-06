class SubscribePolicy < ApplicationPolicy

  def create?
    return false if user.guest?
    !record.subscribeable.subscribes.exists?(user_id: user.id)
  end

  def destroy?
    return false if user.guest?
    record.subscribeable.subscribes.exists?(user_id: user.id)
  end
end
