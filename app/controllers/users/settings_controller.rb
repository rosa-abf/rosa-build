class Users::SettingsController < Users::BaseController
  include AvatarHelper

  before_action :set_current_user
  before_action -> { authorize @user, :update? }

  def profile
    if request.patch?
      send_confirmation = params[:user][:email] != @user.email
      if @user.update_without_password(params[:user])
        update_avatar(@user, params)
        if send_confirmation
          @user.confirmed_at = @user.confirmation_sent_at = nil
          @user.send_confirmation_instructions
        end
        flash[:notice] = t('flash.user.saved')
        redirect_to profile_settings_path and return
      end
      flash[:error] = t('flash.user.save_error')
      flash[:warning] = @user.errors.full_messages.join('. ')
    end
  end

  def reset_auth_token
    @user.reset_authentication_token!
    flash[:notice] = t("flash.user.reset_auth_token")
    redirect_to profile_settings_path
  end

  def private
    if request.patch?
      if @user.update_with_password(params[:user])
        flash[:notice] = t('flash.user.saved')
        redirect_to private_settings_path and return
      end
      flash[:error] = t('flash.user.save_error')
      flash[:warning] = @user.errors.full_messages.join('. ')
    end
  end

  def notifiers
    if request.patch?
      if @user.notifier.update_attributes(params[:settings_notifier])
        flash[:notice] = I18n.t("flash.settings.saved")
        redirect_to notifiers_settings_path and return
      end
      flash[:error] = I18n.t("flash.settings.save_error")
    end
  end

  def builds_settings
    @user.builds_setting ||= @user.build_builds_setting
    if request.patch?
      if @user.builds_setting.update_attributes(params[:user_builds_setting])
        flash[:notice] = I18n.t("flash.settings.saved")
        redirect_to builds_settings_settings_path and return
      end
      flash[:error] = I18n.t("flash.settings.save_error")
    end
  end

end
