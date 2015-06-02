class Api::V1::AdvisoriesController < Api::V1::BaseController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: %i(index show) if APP_CONFIG['anonymous_access']
  before_action :load_advisory,           only: %i(show update)
  before_action :load_build_list,         only: %i(create update)

  def index
    authorize :advisory
    @advisories = Advisory.includes(:platforms, :projects).paginate(paginate_params)
  end

  def show
    @packages_info = @advisory.fetch_packages_info
  end

  def create
    authorize :advisory
    if @build_list.can_attach_to_advisory? &&
        @build_list.associate_and_create_advisory(advisory_params) &&
        @build_list.save
      render_json_response @build_list.advisory, 'Advisory has been created successfully'
    else
      render_validation_error @build_list.advisory, error_message(@build_list, 'Advisory has not been created')
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

  def advisory_params
    subject_params(Advisory)
  end

  def load_build_list
    @build_list = BuildList.find params[:build_list_id]
    authorize @build_list.save_to_platform, :local_admin_manage?
  end

  def load_advisory
    @advisory = Advisory.find_by(advisory_id: params[:id]) if params[:id]
    authorize @advisory if @advisory
  end

end
