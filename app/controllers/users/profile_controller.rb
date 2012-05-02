# -*- encoding : utf-8 -*-
class Users::ProfileController < Users::BaseController
  autocomplete :user, :uname

  def show
    @groups = @user.groups.uniq
    @platforms = @user.platforms.paginate(:page => params[:platform_page], :per_page => 10)
    @projects = @user.projects.paginate(:page => params[:project_page], :per_page => 10)
  end
end
