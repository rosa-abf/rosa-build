class UserBuildsSettingPolicy < ApplicationPolicy

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(external_nodes) + [platforms: []]
  end

end
