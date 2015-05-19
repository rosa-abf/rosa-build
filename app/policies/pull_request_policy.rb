class PullRequestPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    is_admin? || ProjectPolicy.new(user, record.to_project).show?
  end
  alias_method :read?,      :show?
  alias_method :commits?,   :show?
  alias_method :files?,     :show?
  alias_method :create?,    :show?

  def update?
    return false if user.guest?
    is_admin? || record.user_id == user.id || local_writer?(record.to_project)
  end

  def merge?
    return false if user.guest?
    is_admin? || local_writer?(record.to_project)
  end

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(
      body
      from_ref
      issue_attributes
      title
      to_ref
    )
  end

end
