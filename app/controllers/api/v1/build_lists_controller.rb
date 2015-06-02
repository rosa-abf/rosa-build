class Api::V1::BuildListsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :load_build_list, only: %i(
                                            cancel
                                            create_container
                                            publish
                                            publish_into_testing
                                            reject_publish
                                            rerun_tests
                                            show
                                          )
  skip_before_action :authenticate_user!, only: %i(show index) if APP_CONFIG['anonymous_access']

  def show
    authorize @build_list
    respond_to :json
  end

  def index
    authorize :build_list
    @project = Project.find(params[:project_id]) if params[:project_id].present?
    authorize @project, :show? if @project
    filter = BuildList::Filter.new(@project, current_user, params[:filter] || {})
    @build_lists = filter.find.includes(:build_for_platform,
                                        :save_to_repository,
                                        :save_to_platform,
                                        :project,
                                        :user,
                                        :arch)

    @build_lists = @build_lists.recent.paginate(paginate_params)
    respond_to :json
  end

  def create
    save_to_repository = Repository.find_by(id: build_list_params[:save_to_repository_id])

    @build_list                  = current_user.build_lists.new(build_list_params)
    @build_list.save_to_platform = save_to_repository.platform if save_to_repository
    @build_list.priority         = current_user.build_priority # User builds more priority than mass rebuild with zero priority

    create_subject @build_list
  end

  def cancel
    authorize @build_list
    render_json :cancel
  end

  def publish
    authorize @build_list
    @build_list.publisher = current_user
    render_json :publish
  end

  def reject_publish
    authorize @build_list
    @build_list.publisher = current_user
    render_json :reject_publish
  end

  def create_container
    authorize @build_list
    render_json :create_container, :publish_container
  end

  def rerun_tests
    authorize @build_list
    render_json :rerun_tests
  end

  def publish_into_testing
    authorize @build_list
    @build_list.publisher = current_user
    render_json :publish_into_testing
  end

  private

  def build_list_params
    subject_params(BuildList)
  end

  # Private: before_action hook which loads BuidList.
  def load_build_list
    @build_list = BuildList.find params[:id]
  end

  def render_json(action_name, action_method = nil)
    if @build_list.try("can_#{action_name}?") && @build_list.send(action_method || action_name)
      render_json_response @build_list, t("layout.build_lists.#{action_name}_success")
    else
      render_validation_error @build_list, t("layout.build_lists.#{action_name}_fail")
    end
  end
end
