class Users::ProfileController < Users::BaseController
  skip_before_filter :authenticate_user!, only: :show if APP_CONFIG['anonymous_access']

  def show
    @path, page = user_path, params[:page].to_i
    @projects = @user.own_projects.search(params[:search]).recent
    if request.xhr?
      if params[:visibility] != 'hidden'
        @projects = @projects.opened
        @hidden = true
      else
        @projects = @projects.by_visibilities('hidden').accessible_by(current_ability, :read)
      end
      render partial: 'shared/profile_projects', layout: nil, locals: {projects: paginate_projects(page)}
    else
      @projects = @projects.opened
      @projects = paginate_projects(page)
    end
  end

  protected

  def paginate_projects(page)
    @projects.paginate(page: (page>0 ? page : nil), per_page: 24)
  end
end
