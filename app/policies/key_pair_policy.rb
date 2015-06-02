class KeyPairPolicy < ApplicationPolicy

  def create?
    return false unless record.repository
    is_admin? || local_admin?(record.repository.platform)
  end
  alias_method :destroy?, :create?

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(public secret repository_id)
  end

end
