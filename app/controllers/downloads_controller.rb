class DownloadsController < ApplicationController
  before_filter :authenticate_user!
  #before_filter :check_global_access, :except => [:test_sudo]

  def index
    @downloads = Download.paginate :page => params[:page], :per_page => 30
  end
  
  def refresh
    Download.rotate_nginx_log
    Download.parse_and_remove_nginx_log
    
    redirect_to downloads_path, :notice => t('flash.downloads.statistics_refreshed')
  end
  
  def test_sudo
    system('sudo touch /home/rosa/test_sudo1.txt')
    system('/usr/bin/sudo /bin/touch /home/rosa/test_sudo2.txt')
    redirect_to downloads_path, :notice => 'Sudo tested!'
  end
end
