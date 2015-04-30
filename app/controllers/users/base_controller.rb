class Users::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :find_user

  protected

  def find_user
    if user_id = params[:uname] || params[:user_id] || params[:id]
      @user = User.opened.find_by_insensitive_uname! user_id
    end
  end

  def set_current_user
    @user = current_user
  end
end
