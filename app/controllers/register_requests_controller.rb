# -*- encoding : utf-8 -*-
class RegisterRequestsController < ApplicationController
  load_and_authorize_resource

  before_filter :find_register_request, :only => [:approve, :reject]

  def index
    @register_requests = @register_requests.unprocessed.paginate(:page => params[:page])
  end

  def new
#    render :layout => 'sessions'
    redirect_to '/invite.html'
  end

  def show_message
  end

  def create
    RegisterRequest.create(params[:register_request])
    redirect_to '/thanks.html' #show_message_register_requests_path
  end

  def update
    case params[:update_type]
      when 'approve' # see approve method
      when 'reject'  # see reject method
    end
    redirect_to :action => :index
  end

  def approve
    @register_request.update_attributes(:approved => true, :rejected => false)
    redirect_to :action => :index
  end

  def reject
    @register_request.update_attributes(:approved => false, :rejected => true)
    redirect_to :action => :index
  end

  protected

    def find_register_request
      @register_request = RegisterRequest.find(params[:register_request_id])
    end
end
