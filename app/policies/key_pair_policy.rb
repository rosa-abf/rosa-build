class KeyPairPolicy < ApplicationPolicy

  def create?
    return false unless record.repository
    is_admin? || local_admin?(record.repository.platform)
  end
  alias_method :destroy?, :create?

end
