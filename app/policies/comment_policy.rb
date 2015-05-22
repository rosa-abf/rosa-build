class CommentPolicy < ApplicationPolicy

  def create?
    !user.guest? && ProjectPolicy.new(user, record.project).show?
  end
  alias_method :new_line?, :create?

  def update?
    return false if user.guest?
    is_admin? || record.user_id == user.id || local_admin?(record.project)
  end
  alias_method :destroy?, :update?

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(body data)
  end

end
