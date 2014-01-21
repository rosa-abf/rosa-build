class Api::V1::UsersController < Api::V1::BaseController

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:show] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource :user, only: :show
  before_filter :set_current_user, except: :show

  def show
    @user = User.opened.find params[:id] # dont show system users
  end

  def show_current_user
    render :show
  end

  def update
    user_params = params[:user] || {}
    send_confirmation = user_params[:email] != @user.email
    if @user.update_without_password(user_params)
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
      if @user.notifier.update_attributes(params[:notifiers])
        render_json_response @user, 'User notification settings have been updated successfully'
      else
        render_json_response @user, error_message(@user.notifier, 'User notification settings have not been updated'), 422
      end
    else
      render :notifiers
    end
  end

  protected

  def set_current_user
    @user = current_user
  end

end
