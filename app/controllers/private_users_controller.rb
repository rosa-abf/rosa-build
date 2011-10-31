class PrivateUsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_global_access, :except => [:destroy]

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
  	user = PrivateUser.find(params[:id])
    can_perform? user if user
  	redirect_to platform_private_users_path(params[:platform_id])
  end
end
