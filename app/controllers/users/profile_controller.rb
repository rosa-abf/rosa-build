# -*- encoding : utf-8 -*-
class Users::ProfileController < Users::BaseController
  skip_before_filter :authenticate_user!, :only => :show if APP_CONFIG['anonymous_access']

  def show
    @projects = @user.projects.opened.search(params[:search]).recent
                     .paginate(:page => params[:page], :per_page => 24)
  end
end
