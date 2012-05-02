# -*- encoding : utf-8 -*-
class Admin::RegisterRequestsController < Admin::BaseController
  def index
    @register_requests = @register_requests.send((params[:scope] || 'unprocessed').to_sym).paginate(:page => params[:page])
  end

  def update
    if params[:update_type].present? and params[:request_ids].present?
      updates = RegisterRequest.where(:id => params[:request_ids])
      case params[:update_type]
      when 'approve' # see approve method
        updates.each {|req| req.update_attributes(:approved => true, :rejected => false)}
      when 'reject'  # see reject method
        updates.each {|req| req.update_attributes(:approved => false, :rejected => true)}
      end
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
end
