class CollaboratorPolicy < ApplicationPolicy

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(role actor_id actor_type)
  end

end
