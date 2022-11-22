class TokenPolicy < ApplicationPolicy

  def show?
    is_admin? || owner?(record.subject) || local_admin?(record.subject)
  end
  alias_method :create?,     :show?
  alias_method :read?,       :show?
  alias_method :withdraw?,   :show?
  alias_method :reactivate?, :show?

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(description)
  end

end
