class Users::RegistrationsController < Devise::RegistrationsController
  before_filter :update_sanitized_params, if: :devise_controller?

  # POST /resource
  def create
    # Try stop bots
    if params[:recaptcha_response_field].present?
      respond_with(resource, location: after_inactive_sign_up_path_for(resource))
      return
    end
    super
  end

  protected

  def update_sanitized_params
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:uname, :name, :email, :password, :password_confirmation)
    end
  end

end