# -*- encoding : utf-8 -*-
class RegisterRequestsController < ApplicationController
  load_and_authorize_resource

  def index
    @register_requests = @register_requests.unprocessed.paginate(:page => params[:page])
  end

  def new
    render :layout => 'sessions'
  end

  def show_message
  end

  def create
    if @register_request = RegisterRequest.create(params[:register_request])
      redirect_to show_message_register_requests_path
    else
      redirect_to :action => :new
    end
  end

  def approve
    @register_request.update_attributes(:approved => true, :rejected => false)
  end

  def reject
    @register_request.update_attributes(:approved => false, :rejected => true)
  end
end

