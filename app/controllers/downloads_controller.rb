class DownloadsController < ApplicationController
  def index
    @downloads = Download.paginate :page => params[:page], :per_page => 30
  end
end
