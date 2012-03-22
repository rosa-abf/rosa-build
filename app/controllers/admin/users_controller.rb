# -*- encoding : utf-8 -*-
class Admin::UsersController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :except => :create
  authorize_resource :only => :create

  def index
    @filter = params[:filter] || 'all'
  end

  def new
  end

  def create
    @user = User.new params[:user]
    @user.role = params[:role]
    @user.uname = params[:uname]
    if @user.save
      flash[:notice] = t('flash.user.saved')
      redirect_to users_path
    else
      flash[:error] = t('flash.user.save_error')
      render :action => :new
    end
  end

  def profile
  end

  def update
    @user.role = params[:role]
    if @user.update_without_password(params[:user])
      if @user.avatar && params[:delete_avatar] == '1'
        @user.avatar = nil
        @user.save
      end
      flash[:notice] = t('flash.user.saved')
      redirect_to users_path#edit_user_path(@user)
    else
      flash[:error] = t('flash.user.save_error')
      flash[:warning] = @user.errors.full_messages.join('. ')
      render(:action => :profile)
    end
  end

  def destroy
    @user.destroy
    flash[:notice] = t("flash.user.destroyed")
    redirect_to users_path
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
    @total_user = @users.count
    @users = @users.order(order)

    render :partial =>'users_ajax', :layout => false
  end
end