class ProductPolicy < ApplicationPolicy

  def index?
    record.platform.main?
  end

  def show?
    is_admin? || PlatformPolicy.new(user, record.platform).show?
  end
  alias_method :read?, :show?

  def create?
    return false unless record.platform
    is_admin? || record.platform.main? && ( owner?(record.platform) || local_admin?(record.platform) )
  end
  alias_method :clone?,   :create?
  alias_method :destroy?, :create?
  alias_method :update?,  :create?

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(
      autostart_status
      description
      main_script
      name
      params
      platform_id
      project_id
      project_version
      time_living
    )
  end

end
