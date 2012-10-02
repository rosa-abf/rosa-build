# -*- encoding : utf-8 -*-
class Users::ProfileController < Users::BaseController
  autocomplete :user, :uname
  skip_before_filter :authenticate_user!, :only => :show if APP_CONFIG['anonymous_access']

  def show
    @projects = @user.projects.by_visibilities(['open']).
      search(params[:search]).search_order.
      paginate(:page => params[:page], :per_page => 25)
  end
end
