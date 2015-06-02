class ProductBuildListPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    is_admin? || ProductPolicy.new(user, record.product).show?
  end
  alias_method :log?,  :show?
  alias_method :read?, :show?

  def create?
    return false unless record.project && record.product
    is_admin? || ProjectPolicy.new(user, record.project).write? || ProductPolicy.new(user, record.product).update?
  end
  alias_method :cancel?, :create?

  def update?
    is_admin? || ProductPolicy.new(user, record.product).update?
  end

  def destroy?
    is_admin? || ProductPolicy.new(user, record.product).destroy?
  end

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(
      base_url
      branch
      commit_hash
      main_script
      not_delete
      params
      product_id
      product_name
      project_id
      project_version
      status
      time_living
    )
  end

end
