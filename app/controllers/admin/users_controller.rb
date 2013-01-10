# -*- encoding : utf-8 -*-
class Admin::UsersController < Admin::BaseController
  include AvatarHelper
  prepend_before_filter :find_user
  load_and_authorize_resource :read => :system

  def index
    @filter = params[:filter] || 'all'
  end

  def system
    @users = @users.system
    @filter = 'system'
    render :index
  end

  def new
    @user.role = 'system' if params[:system] == 'true'
  end

  def create
    @user.role = params[:role]
    @user.email, @user.password = "#{@user.uname}@rosalinux.ru", SecureRandom.base64 if @user.system?
    @user.confirmed_at = Time.now.utc
    if (@user.save rescue false)
      flash[:notice] = t('flash.user.saved')
      flash[:warning] = @user.authentication_token
      redirect_to(@user.system? ? system_admin_users_path : admin_users_path)
    else
      flash[:error] = t('flash.user.save_error')
      flash[:warning] = @user.errors.full_messages.join('. ')
      @system = @user.system?

      render :action => :new
    end
  end

  def edit
  end

  def update
    @user.role = params[:role]
    if @user.update_without_password(params[:user])
      update_avatar(@user, params)
      flash[:notice] = t('flash.user.saved')
      redirect_to admin_users_path
    else
      flash[:error] = t('flash.user.save_error')
      flash[:warning] = @user.errors.full_messages.join('. ')
      render :action => :edit
    end
  end

  def destroy
    @user.destroy
    flash[:notice] = t("flash.user.destroyed")
    redirect_to(@user.system? ? system_admin_users_path : admin_users_path)
  end

  def list
    if action_name == 'list'
      colName, @users = ['users.name', 'users.uname', 'users.email'], @users.opened
    else # system_list
      colName, @users = ['users.uname'], @users.system
    end
    sort_col = params[:iSortCol_0] || 0
    sort_dir = params[:sSortDir_0]=="asc" ? 'asc' : 'desc'
    order = "#{colName[sort_col.to_i]} #{sort_dir}"

    @users = @users.paginate(:page => (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i).to_i + 1, :per_page => params[:iDisplayLength])
    @total_users = @users.count
    if !params[:sSearch].blank? && search = "%#{params[:sSearch]}%"
      @users = @users.where('users.name ILIKE ? or users.uname ILIKE ? or users.email ILIKE ?', search, search, search)
    end
    @filter = params[:filter] || 'all'
    @users = @users.send(@filter) if ['real', 'admin', 'banned', 'tester'].include? @filter
    @users = @users.order(order)

    render :partial => "#{action_name == 'system_list' ? 'system_' : ''}users_ajax", :layout => false
  end

  def system_list
    list
  end

  def reset_auth_token
    @user.reset_authentication_token!
    flash[:notice] = t("flash.user.reset_auth_token")
    flash[:warning] = @user.authentication_token
    redirect_to system_admin_users_path
  end

  protected

  def find_user
    @user = User.find_by_uname!(params[:id]) if params[:id]
  end
end
