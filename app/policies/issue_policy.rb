class IssuePolicy < ApplicationPolicy

  def index?
    # record.project.has_issues?
    true
  end

  def show?
    return false unless record.project.has_issues?
    ProjectPolicy.new(user, record.project).show?
  end
  alias_method :create?, :show?
  alias_method :read?,   :show?

  def update?
    return false if user.guest?
    is_admin? || record.user_id == user.id || local_admin?(record.project)
  end

end
