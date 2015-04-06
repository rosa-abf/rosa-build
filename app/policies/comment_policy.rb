class CommentPolicy < ApplicationPolicy

  def create?
    ProjectPolicy.new(user, record.project).show?
  end
  alias_method :new_line?, :create?

  def update?
    is_admin? || record.user_id == user.id || local_admin?(record.project)
  end
  alias_method :destroy?, :update?

end
