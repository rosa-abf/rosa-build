# -*- encoding : utf-8 -*-
class Users::ProfileController < Users::BaseController
  autocomplete :user, :uname
  skip_before_filter :authenticate_user!, :only => :show if APP_CONFIG['anonymous_access']

  def show
    @projects = @user.projects.by_visibilities(['open'])
  end
end
