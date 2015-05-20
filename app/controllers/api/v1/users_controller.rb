class Api::V1::UsersController < Api::V1::BaseController

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:show] if APP_CONFIG['anonymous_access']
  before_action :load_user, only: %i(show)
  before_action :set_current_user, except: :show

  def show
    @user = User.opened.find params[:id] # dont show system users
  end

  def show_current_user
    render :show
  end

  def update
    user_params = params[:user] || {}
    send_confirmation = user_params[:email] != @user.email
    if @user.update_without_password(subject_params(User))
      if send_confirmation
        @user.confirmed_at, @user.confirmation_sent_at = nil
        @user.send_confirmation_instructions
      end
      render_json_response @user, 'User has been updated successfully'
    else
      render_validation_error @user, "#{class_name} has not been updated"
    end
  end

  def notifiers
    if request.put?
      if @user.notifier.update_attributes(notifier_params)
        render_json_response @user, 'User notification settings have been updated successfully'
      else
        render_json_response @user, error_message(@user.notifier, 'User notification settings have not been updated'), 422
      end
    end
  end

  protected

  def notifier_params
    permit_params(:notifiers, *policy(SettingsNotifier).permitted_attributes)
  end

  def set_current_user
    authorize @user = current_user
  end

  # Private: before_action hook which loads User.
  def load_user
    authorize @user = User.find(params[:id])
  end

end
