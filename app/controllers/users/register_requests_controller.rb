class Users::RegisterRequestsController < ApplicationController
  before_action :user_choose_locale
  layout 'invite'

  def new
    if APP_CONFIG['preregistration']
      render :invite
    else
      redirect_to new_user_registration_path
    end
  end

  def create
    params[:register_request][:language] = I18n.locale if params[:register_request]
    RegisterRequest.create(params[:register_request])
    render :thanks
  end

  protected

  def user_choose_locale
    I18n.locale = params[:format] if User::LANGUAGES.include?(params[:format])
  end
end
