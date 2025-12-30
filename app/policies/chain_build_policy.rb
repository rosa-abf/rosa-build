class ChainBuildPolicy < ApplicationPolicy
  def show?
    record.user_id == user.id
  end

  alias_method :last?, :show?
end