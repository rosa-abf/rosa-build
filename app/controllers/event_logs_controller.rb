# coding: UTF-8
class EventLogsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    @event_logs = EventLog.default_order.eager_loading.paginate :page => params[:page]
  end
end
