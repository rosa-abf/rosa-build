class PrivateUsersController < ApplicationController
  before_filter :authenticate_user!

  def index
  	@private_users = PrivateUser.where(:platform_id => params[:platform_id]).paginate :page => params[:page]
    @platform = Platform.find(params[:platform_id])
  end

  def create
  	pair = PrivateUser.generate_pair(params[:platform_id], current_user.id)
    redirect_to platform_private_users_path(params[:platform_id]), 
    			:notice => "Логин: #{ pair[:login] } Пароль: #{ pair[:pass] }"
  end

  def destroy
  	PrivateUser.find(params[:id]).destroy
  	redirect_to platform_private_users_path(params[:platform_id])
  end
end
