class Users::BaseController < ApplicationController
  layout 'bootstrap'

  before_filter :authenticate_user!
  before_filter :find_user

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
