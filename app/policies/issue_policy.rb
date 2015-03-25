class IssuePolicy < ApplicationPolicy

  def index?
    # record.project.has_issues?
    true
  end

  def show?
    ProjectPolicy.new(user, record.project).show?
  end
  alias_method :create?, :show?
  alias_method :read?,   :show?

  def update?
    record.user_id == user.id || local_admin?(record.project)
  end

end
