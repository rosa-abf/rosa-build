class TokenApiPolicy < ApplicationPolicy

  def index?
    user.access_to_token_api
  end

  alias_method :show?,       :index?
  alias_method :create?,     :index?
  alias_method :update?,     :index?
  alias_method :destroy?,    :index?
  alias_method :activate?,   :index?
  alias_method :deactivate?, :index?

  def permitted_attributes
    %i(description)
  end

end