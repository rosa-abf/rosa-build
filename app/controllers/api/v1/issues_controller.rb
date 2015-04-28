class Api::V1::IssuesController < Api::V1::BaseController
  include Api::V1::Issueable

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: %i(index group_index show) if APP_CONFIG['anonymous_access']

  before_action :load_group,        only: :group_index
  before_action :load_project
  skip_before_action :load_project, only: %i(all_index user_index group_index)
  before_action :load_issue,        only: %i(show update index)

  def index
    @issues = @project.issues
    render_issues_list
  end

  def all_index
    authorize :issue, :index?
    project_ids = get_all_project_ids membered_projects.pluck(:id)
    @issues = Issue.where(project_id: project_ids)
    render_issues_list
  end

  def user_index
    authorize :issue, :index?
    project_ids = get_all_project_ids current_user.projects.pluck(:id)
    @issues = Issue.where(project_id: project_ids)
    render_issues_list
  end

  def group_index
    project_ids = @group.projects.pluck(:id)
    project_ids = membered_projects.where(id: project_ids).pluck(:id)
    @issues = Issue.where(project_id: project_ids)
    render_issues_list
  end

  def show
    if @issue.pull_request
      redirect_to api_v1_project_pull_request_path(@project.id, @issue.serial_id)
    else
      respond_to :json
    end
  end

  def create
    @issue      = @project.issues.new
    @issue.assign_attributes subject_params(Issue, @issue)
    @issue.user = current_user
    create_subject @issue
  end

  def update
    @issue.labelings.destroy_all if params[:update_labels] && policy(@project).write?
    if params[:issue] && status = params[:issue].delete(:status)
      @issue.set_close(current_user) if status == 'closed'
      @issue.set_open if status == 'open'
    end
    update_subject @issue
  end

  private

  def render_issues_list
    @issues = @issues.preload(:user, :assignee, :labels, :project).without_pull_requests
    if params[:status] == 'closed'
      @issues = @issues.closed
    else
      @issues = @issues.opened
    end

    if action_name == 'index' && params[:assignee].present?
      case params[:assignee]
      when 'none'
        @issues = @issues.where(assigned_id: nil)
      when '*'
        @issues = @issues.where('issues.assigned_id IS NOT NULL')
      else
        @issues = @issues.where('issues.assignees_issues.uname = ?', params[:assignee])
      end
    end

    if %w[all_index user_index group_index].include?(action_name)
      case params[:filter]
      when 'created'
        @issues = @issues.where(user_id: current_user)
      when 'all'
      else
        @issues = @issues.where(assignee_id: current_user)
      end
    else
      @issues.where('users.uname = ?', params[:creator]) if params[:creator].present?
    end

    if params[:labels].present?
      labels = params[:labels].split(',').map(&:strip).select(&:present?)
      @issues = @issues.where('labels.name IN (?)', labels)
    end

    sort = params[:sort] == 'updated' ? 'issues.updated_at' : 'issues.created_at'
    direction = params[:direction] == 'asc' ? 'ASC' : 'DESC'
    @issues = @issues.order("#{sort} #{direction}")

    @issues = @issues.where('issues.created_at >= to_timestamp(?)', params[:since]) if params[:since] =~ /\A\d+\z/
    @issues = @issues.paginate(paginate_params)

    respond_to do |format|
      format.json { render :index }
    end
  end

end
