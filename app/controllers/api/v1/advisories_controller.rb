class Api::V1::AdvisoriesController < Api::V1::BaseController
  before_action :authenticate_user!
  # skip_before_action :authenticate_user!, only: %i(index show) if APP_CONFIG['anonymous_access']
  before_action :load_advisory,           only: %i(show update attach_build_list destroy)

  def index
    authorize :advisory_api
    @advisories = Advisory.all.paginate(paginate_params)
  end

  def show
    authorize :advisory_api
  end

  def create
    authorize :advisory_api
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
    authorize :advisory_api
    update_subject @advisory
  end

  def destroy
    authorize :advisory_api
    destroy_subject @advisory
  end

  protected

  def advisory_params
    subject_params(Advisory)
  end

  def load_advisory
    @advisory = Advisory.find_by(advisory_id: params[:id])
    raise ActiveRecord::RecordNotFound unless @advisory
  end

end
