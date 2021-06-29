class Api::V1::AdvisoriesController < Api::V1::BaseController
  before_action :authenticate_user!
  # skip_before_action :authenticate_user!, only: %i(index show) if APP_CONFIG['anonymous_access']
  before_action :load_advisory,           only: %i(show update attach_build_list destroy)

  def index
    authorize :advisory
    @advisories = Advisory.all.paginate(paginate_params)
  end

  def show
  end

  def create
    authorize :advisory
    projects = JSON.parse(request.body.string).try(:[], 'advisory').try(:[], 'projects')
    result = AdvisoryService::Create.call(
      advisory_params: advisory_params,
      projects: projects
    )
    if result[:success]
      render_json_response result[:advisory], 'Advisory has been created successfully'
    else
      render_validation_error result[:advisory], 'Advisory has not been created'
    end
  end

  def update
    update_subject @advisory
  end

  def destroy
    @advisory.platforms.each do |pl|
      authorize pl, :local_admin_manage?
    end
    destroy_subject @advisory
  end

  protected

  def advisory_params
    subject_params(Advisory)
  end

  def load_advisory
    @advisory = Advisory.find_by(advisory_id: params[:id]) if params[:id]
    authorize @advisory if @advisory
  end

end
