class GroupPolicy < ApplicationPolicy

  def index?
    !user.guest?
  end
  alias_method :create?,      :index?
  alias_method :remove_user?, :index?

  def show?
    true
  end

  def reader?
    !user.guest? && ( is_admin? || local_reader? )
  end

  def write?
    !user.guest? && ( is_admin? || owner? || local_writer? )
  end

  def update?
    !user.guest? && ( is_admin? || owner? || local_admin? )
  end
  alias_method :add_member?,      :update?
  alias_method :manage_members?,  :update?
  alias_method :members?,         :update?
  alias_method :remove_member?,   :update?
  alias_method :remove_members?,  :update?
  alias_method :update_member?,   :update?

  def destroy?
    !user.guest? && ( is_admin? || owner? )
  end

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    pa = %i(avatar description delete_avatar default_branch)
    pa << :uname if record.new_record?
    pa
  end

  class Scope < Scope
    def show
      scope
    end
  end

end
