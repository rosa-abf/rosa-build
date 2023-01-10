class AdvisoryApiPolicy < ApplicationPolicy

  def index?
    user.access_to_advisories_api
  end

  alias_method :show?,             :index?
  alias_method :create?,           :index?
  alias_method :update?,           :index?
  alias_method :destroy?,          :index?

  def permitted_attributes
    %i(
      update_type
      description
      references
    )
  end

end