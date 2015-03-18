class HookPolicy < ApplicationPolicy

  def show?
    policy(record.project).update?
  end
  alias_method :read?,    :show?
  alias_method :create?,  :show?
  alias_method :destroy?, :show?
  alias_method :update?,  :show?

end
