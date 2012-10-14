# -*- encoding : utf-8 -*-
class Api::V1::BaseController < ApplicationController
  include Api::V1::BaseHelper
  #respond_to :json

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { render :json => {:message => t("flash.exception_message")}.to_json, :status => 403 }
    end
  end

end
