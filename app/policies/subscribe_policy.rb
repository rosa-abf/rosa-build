class SubscribePolicy < ApplicationPolicy

  def create?
    !user.guest? && record.subscribeable.subscribes.exists?(user_id: user.id)
  end

  def destroy?
    !user.guest? &&
      user.id == record.user_id &&
      record.subscribeable.subscribes.exists?(user_id: user.id)
  end
end
