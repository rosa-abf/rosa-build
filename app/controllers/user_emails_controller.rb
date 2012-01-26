# coding: UTF-8
class UserEmailsController < UsersController
  before_filter :find_user

  def index
    @emails = @user.emails
    (5 - @user.emails.count).times {|e| @emails << UserEmail.new(:user_id => @user) }
  end

  def update
    @user.role = params[:user][:role]
    if @user.update_attributes(params[:user])
      flash[:notice] = t('flash.user.saved')
      redirect_to users_path
    else
      flash[:error] = t('flash.user.save_error')
      render :action => :edit
    end
  end

  def destroy
    @user.destroy
    flash[:notice] = t("flash.user.destroyed")
    redirect_to users_path
  end

end
