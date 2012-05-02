# -*- encoding : utf-8 -*-
class Users::BaseController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_user

  protected

  def find_user
    if user_id = params[:owner_name] || params[:user_id] || params[:id]
      @user = User.find_by_owner_name! user_id
    end
  end
end
