class Users::RegistrationsController < Devise::RegistrationsController
  # POST /resource
  def create
    # Try stop bots
    if params[:recaptcha_response_field].present?
      respond_with(resource, location: after_inactive_sign_up_path_for(resource))
      return
    end
    super
  end
end