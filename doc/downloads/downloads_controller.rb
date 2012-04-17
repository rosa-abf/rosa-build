# -*- encoding : utf-8 -*-
class DownloadsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    @downloads = Download.paginate :page => params[:page], :per_page => 30
  end
  
  def refresh
    Download.rotate_nginx_log
    Download.parse_and_remove_nginx_log
    
    redirect_to downloads_path, :notice => t('flash.downloads.statistics_refreshed')
  end
end
