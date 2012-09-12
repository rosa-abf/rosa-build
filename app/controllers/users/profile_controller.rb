# -*- encoding : utf-8 -*-
class Users::ProfileController < Users::BaseController
  autocomplete :user, :uname

  def show
    @projects = @user.projects.by_visibilities(['open'])
  end
end
