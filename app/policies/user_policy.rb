class UserPolicy < ApplicationPolicy

  def show?
    true
  end

  def update?
    is_admin? || record == user
  end
  alias_method :notifiers?,         :update?
  alias_method :show_current_user?, :update?
  alias_method :write?,             :update?

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(
      company
      current_password
      delete_avatar
      email
      hide_email
      language
      location
      login
      name
      password
      password_confirmation
      professional_experience
      remember_me
      site
      sound_notifications
      uname
    )
  end

  class Scope < Scope
    def show
      scope
    end
  end

end
