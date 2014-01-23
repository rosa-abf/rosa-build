class Admin::RegisterRequestsController < Admin::BaseController
  def index
    @register_requests = @register_requests.send((params[:scope] || 'unprocessed').to_sym).paginate(page: params[:page])
  end

  def update
    RegisterRequest.where(id: params[:request_ids]).each(&params[:update_type].to_sym) if params[:update_type].present? && params[:request_ids].present?
    redirect_to action: :index
  end

  def approve
    @register_request.approve
    redirect_to action: :index
  end

  def reject
    @register_request.reject
    redirect_to action: :index
  end
end
