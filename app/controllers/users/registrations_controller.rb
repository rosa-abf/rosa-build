class Users::RegistrationsController < Devise::RegistrationsController
  before_action :update_sanitized_params, if: :devise_controller?
  before_action :check_captcha, only: [:create]

  protected

  def update_sanitized_params
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:uname, :name, :email, :password, :password_confirmation)
    end
  end

  private

  def check_captcha
    unless verify_recaptcha
      self.resource = resource_class.new sign_up_params
      resource.validate # Look for any other validation errors besides Recaptcha
      set_minimum_password_length
      render :new
    end
  end
end
