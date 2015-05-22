class SubscribePolicy < ApplicationPolicy

  def create?
    return false if user.guest?
    return true if record.subscribeable.is_a?(Grit::Commit)
    !record.subscribeable.subscribes.exists?(user_id: user.id)
  end

  def destroy?
    return false if user.guest?
    return true if record.subscribeable.is_a?(Grit::Commit)
    record.subscribeable.subscribes.exists?(user_id: user.id)
  end

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(status user_id)
  end

end
