# -*- encoding : utf-8 -*-
class Admin::UsersController < Admin::BaseController
  prepend_before_filter :find_user

  def index
    @filter = params[:filter] || 'all'
  end

  def new
  end

  def create
    @user.role = params[:role]
    @user.confirmed_at = Time.now.utc
    if @user.save
      flash[:notice] = t('flash.user.saved')
      redirect_to admin_users_path
    else
      flash[:error] = t('flash.user.save_error')
      flash[:warning] = @user.errors.full_messages.join('. ')
      render :action => :new
    end
  end

  def edit
  end

  def update
    @user.role = params[:role]
    if @user.update_without_password(params[:user])
      if @user.avatar && params[:delete_avatar] == '1'
        @user.avatar = nil
        @user.save
      end
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
    redirect_to admin_users_path
  end

  def list
    colName = ['users.name', 'users.uname', 'users.email']
    sort_col = params[:iSortCol_0] || 0
    sort_dir = params[:sSortDir_0]=="asc" ? 'asc' : 'desc'
    order = "#{colName[sort_col.to_i]} #{sort_dir}"

    @users = @users.paginate(:page => (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i).to_i + 1, :per_page => params[:iDisplayLength])
    @total_users = @users.count
    if !params[:sSearch].blank? && search = "%#{params[:sSearch]}%"
      @users = @users.where('users.name ILIKE ? or users.uname ILIKE ? or users.email ILIKE ?', search, search, search)
    end
    @filter = params[:filter] || 'all'
    @users = @users.send(@filter) if ['real', 'admin', 'banned'].include? @filter
    @users = @users.order(order)

    render :partial => 'users_ajax', :layout => false
  end

  protected

  def find_user
    @user = User.find_by_uname!(params[:id]) if params[:id]
  end
end
