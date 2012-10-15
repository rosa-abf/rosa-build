# -*- encoding : utf-8 -*-
class Api::V1::UsersController < Api::V1::BaseController
  
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show] if APP_CONFIG['anonymous_access']

  def show
    @user = User.where(:id => params[:id]).first
    if @user
      render :show
    else
      render_json_response User.new, "User with id='#{params[:id]}' does not exist", 422
    end
  end

end