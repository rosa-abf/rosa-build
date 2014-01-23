class Admin::EventLogsController < Admin::BaseController
  def index
    @event_logs = EventLog.default_order.eager_loading.paginate page: params[:page]
  end
end
