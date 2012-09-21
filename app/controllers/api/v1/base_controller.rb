# -*- encoding : utf-8 -*-
class Api::V1::BaseController < ApplicationController
  before_filter :http_auth
  before_filter :restrict_paginate, :only => :index

  protected

  def restrict_paginate
    params[:per_page] = 30  if params[:per_page].blank? or params[:per_page].to_i < 1
    params[:per_page] = 100 if params[:per_page].to_i >100
  end

  def http_auth
    authenticate_or_request_with_http_basic do |email, password|
      raise HttpBasicAuthError if email.blank? && password.blank?
      @current_user = User.find_by_email(email)
      @current_user && @current_user.valid_password?(password) ? true : raise(HttpBasicWrongPassError)
    end
  end
end
