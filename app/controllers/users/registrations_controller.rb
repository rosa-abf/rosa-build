class Users::RegistrationsController < Devise::RegistrationsController
  before_action :update_sanitized_params, if: :devise_controller?

  def new
    super do |resource|
      if params[:invite_key].to_s.strip.empty?
        resource.invite_key = ''
      else
        invite = Invite.find_by_invite_key(params[:invite_key])
        if !invite || invite.used?
          flash[:error] = I18n.t('errors.messages.bad_invite_key')
          resource.invite_key = ''
        else
          resource.invite_key = params[:invite_key]
        end
      end
    end
  end

  def create
    invite_key = params[:user][:invite_key]
    invite = Invite.find_by_invite_key(invite_key)
    if !invite || invite.used?
      flash[:error] = I18n.t('errors.messages.bad_invite_key')
      self.resource = resource_class.new sign_up_params
      resource.validate
      set_minimum_password_length
      render :new
    else
      super do |r|
        if r.persisted?
          invite.invited_user = r
          invite.save
        end
      end
    end
  end

  protected

  def update_sanitized_params
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:invite_key, :uname, :name, :email, :password, :password_confirmation)
    end
  end
end
