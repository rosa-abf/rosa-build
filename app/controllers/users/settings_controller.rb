class Users::SettingsController < Users::BaseController
  include AvatarHelper
  before_filter :set_current_user

  def profile
    if request.put?
      send_confirmation = params[:user][:email] != @user.email
      if @user.update_without_password(params[:user])
        update_avatar(@user, params)
        if send_confirmation
          @user.confirmed_at = @user.confirmation_sent_at = nil
          @user.send_confirmation_instructions
        end
        flash[:notice] = t('flash.user.saved')
        redirect_to profile_settings_path
      else
        flash[:error] = t('flash.user.save_error')
        flash[:warning] = @user.errors.full_messages.join('. ')
      end
    end
  end

  def reset_auth_token
    @user.reset_authentication_token!
    flash[:notice] = t("flash.user.reset_auth_token")
    redirect_to profile_settings_path
  end

  def private
    if request.put?
      if @user.update_with_password(params[:user])
        flash[:notice] = t('flash.user.saved')
        redirect_to private_settings_path
      else
        flash[:error] = t('flash.user.save_error')
        flash[:warning] = @user.errors.full_messages.join('. ')
        render(:action => :private)
      end
    end
  end

  def notifiers
    if request.put?
      if @user.notifier.update_attributes(params[:settings_notifier])
        flash[:notice] = I18n.t("flash.settings.saved")
        redirect_to notifiers_settings_path
      else
        flash[:error] = I18n.t("flash.settings.save_error")
      end
    end
  end
end
