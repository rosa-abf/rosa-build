class Users::RegistrationsController < Devise::RegistrationsController
  # POST /resource
  def create
    # Try stop bots
    if params[:user].blank? || "#{params[:user][:login]}#{params[:user][:password]}#{params[:recaptcha_response_field]}".present?
      respond_with(resource, :location => after_inactive_sign_up_path_for(resource))
      return
    else
      params[:user][:password] = params[:user].delete(:pazsword)
    end

    super
  end
end
