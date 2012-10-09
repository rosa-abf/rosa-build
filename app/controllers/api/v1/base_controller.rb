# -*- encoding : utf-8 -*-
class Api::V1::BaseController < ApplicationController
  
  before_filter :restrict_paginate, :only => :index
  #respond_to :json

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { render :json => {:message => t("flash.exception_message")}.to_json, :status => 403 }
    end
  end

  protected

  def restrict_paginate
    params[:per_page] = 30  if params[:per_page].to_i < 1
    params[:per_page] = 100 if params[:per_page].to_i >100
  end

  def paginate_params
    {:page => params[:page], :per_page => 20}
  end

end
