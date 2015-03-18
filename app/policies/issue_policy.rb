class IssuePolicy < ApplicationPolicy

  def index?
    record.project.has_issues?
  end

  def show?
    policy(record.project).show?
  end
  alias_method :create?, :show?
  alias_method :read?,   :show?

  def update?
    record.user_id == user.id || local_admin?(record.project)
  end

end
