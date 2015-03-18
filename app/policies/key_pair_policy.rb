class KeyPairPolicy < ApplicationPolicy

  def create?
    key_pair.repository.blank? || local_admin?(record.repository.platform)
  end
  alias_method :destroy?,    :create?

end
