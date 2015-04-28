class IssuePolicy < ApplicationPolicy

  def index?
    # record.project.has_issues?
    true
  end

  def show?
    return true if record.pull_request.present? # for redirect from a issue to a pull request
    return false unless record.project.has_issues?
    ProjectPolicy.new(user, record.project).show?
  end
  alias_method :create?, :show?
  alias_method :read?,   :show?

  def update?
    return false if user.guest?
    is_admin? || record.user_id == user.id || local_admin?(record.project)
  end

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    pa = %i(title body)
    if ProjectPolicy.new(user, record.project).write?
      pa << :assignee_id
      pa << { labelings_attributes: %i(name color label_id) }
      pa << { labelings: [] }
    end
    pa
  end

end
