class Users::ProfileController < Users::BaseController
  include PaginateHelper

  skip_before_filter :authenticate_user!, only: :show if APP_CONFIG['anonymous_access']

  def show
    respond_to do |format|
      format.html do
        @groups = @user.groups.order(:uname)
      end
      format.json do
        @projects = @user.own_projects.search(params[:term]).recent
        case params[:visibility]
        when 'open'
          @projects = @projects.opened
        when 'hidden'
          @projects = @projects.by_visibilities('hidden').accessible_by(current_ability, :read)
        else
          @projects = @projects.accessible_by(current_ability, :read)
        end
        @total_items  = @projects.count
        @projects     = @projects.paginate(paginate_params)
      end
    end
  end

end
