class Api::V1::AdvisoriesController < Api::V1::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index, :show] if APP_CONFIG['anonymous_access']
  load_resource :advisory, :find_by => :advisory_id
  before_filter :find_and_authorize_build_list, :only => [:create, :update]
  authorize_resource :build_list, :only => [:create, :update]

  def index
    @advisories = @advisories.scoped(:include => [:platforms, :projects]).
      paginate(paginate_params)
  end

  def show
    @packages_info = @advisory.fetch_packages_info
  end

  def create
    if @build_list.can_attach_to_advisory? &&
        @build_list.associate_and_create_advisory(params[:advisory]) &&
        @build_list.save
      render_json_response @advisory, 'Advisory has been created successfully'
    else
      render_validation_error @advisory, error_message(@build_list, 'Advisory has not been created')
    end
  end

  def update
    if @advisory && @build_list.can_attach_to_advisory? &&
        @advisory.attach_build_list(@build_list) && @build_list.save
      render_json_response @advisory, "Build list '#{@build_list.id}' has been attached to advisory successfully"
    else
      render_validation_error @advisory, error_message(@build_list, 'Build list has not been attached to advisory')
    end
  end

  protected

  def find_and_authorize_build_list
    @build_list = BuildList.find params[:build_list_id]
    authorize! :local_admin_manage, @build_list.save_to_platform
  end

end
