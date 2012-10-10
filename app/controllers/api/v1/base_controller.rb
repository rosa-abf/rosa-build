# -*- encoding : utf-8 -*-
class Api::V1::BaseController < ApplicationController
  
  #respond_to :json

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { render :json => {:message => t("flash.exception_message")}.to_json, :status => 403 }
    end
  end

  protected

  def paginate_params
    per_page = params[:per_page].to_i
    per_page = 20 if per_page < 1
    per_page = 100 if per_page >100
    {:page => params[:page], :per_page => per_page}
  end

  def validation_failed(subject)
    {:message => "Validation Failed", :errors => subject.errors.messages}.to_json
  end

end
