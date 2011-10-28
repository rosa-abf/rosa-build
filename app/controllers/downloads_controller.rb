class DownloadsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_global_access

  def index
    @downloads = Download.paginate :page => params[:page], :per_page => 30
  end
end
