class HookPolicy < ApplicationPolicy

  def show?
    ProjectPolicy.new(user, record.project).update?
  end
  alias_method :read?,    :show?
  alias_method :create?,  :show?
  alias_method :destroy?, :show?
  alias_method :update?,  :show?

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(data name)
  end

end
