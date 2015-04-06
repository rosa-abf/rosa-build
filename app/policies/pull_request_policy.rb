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

  def create?
    true
  end

  def update?
    is_admin? || record.user_id == record.id || local_writer?(record.to_project)
  end

  def merge?
    is_admin? || local_writer?(record.to_project)
  end

end
