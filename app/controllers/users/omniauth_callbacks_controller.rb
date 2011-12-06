class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def open_id
    # raise env['omniauth.auth'].inspect
    generic
  end

  def passthru
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end

  protected

  def generic
    authentication = Authentication.find_or_initialize_by_provider_and_uid(env['omniauth.auth']['provider'], env['omniauth.auth']['uid'])
    if authentication.new_record?
      if user_signed_in? # New authentication method for current_user
        authentication.user = current_user
        authentication.save
      else # Register new user from session
        session["devise.omniauth_data"] = env["omniauth.auth"].except('extra')
        flash[:notice] = I18n.t "devise.omniauth_callbacks.register"
        redirect_to new_user_registration_url
      end
    else
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => action_name.classify
      sign_in_and_redirect authentication.user, :event => :authentication
    end
  end
end
