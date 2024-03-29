class AdvisoryPolicy < ApplicationPolicy

  def index?
    true
  end
  alias_method :search?, :index?
  alias_method :show?, :index?

  def create?
    !user.guest?
  end
  alias_method :update?, :create?
  alias_method :destroy?, :create?
  alias_method :attach_build_list?, :create?

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(
      update_type
      description
      references
    )
  end

end
