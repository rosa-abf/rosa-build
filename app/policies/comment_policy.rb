class CommentPolicy < ApplicationPolicy

  def create?
    policy(record.project).show?
  end
  alias_method :new_line?, :create?

  def update?
    record.user_id == user.id || local_admin?(record.project)
  end

end
