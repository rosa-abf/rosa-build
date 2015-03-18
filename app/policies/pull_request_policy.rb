class PullRequestPolicy < ApplicationPolicy

  def show?
    policy(record.to_project).show?
  end
  alias_method :read?,      :show?
  alias_method :commits?,   :show?
  alias_method :files?,     :show?

  def create?
    true
  end

  def update?
    record.user_id == record.id || local_writer?(record.to_project)
  end

  def merge?
    local_writer?(record.to_project)
  end

end
