# -*- encoding : utf-8 -*-
class Users::RegisterRequestsController < ApplicationController
  before_filter :user_choose_locale
  layout 'invite'

  def new
    render :invite
  end

  def create
    RegisterRequest.create(params[:register_request])
    render :thanks
  end

  protected

  def user_choose_locale
    I18n.locale = params[:format] if User::LANGUAGES.include?(params[:format])
  end
end
