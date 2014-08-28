class Api::V1::IssuesController < Api::V1::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:index, :group_index, :show] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :group, only: :group_index, find_by: :id, parent: false
  load_and_authorize_resource :project
  skip_load_and_authorize_resource :project, only: [:all_index, :user_index, :group_index]
  load_and_authorize_resource :issue, through: :project, find_by: :serial_id, only: [:show, :update, :create, :index]

  def index
    @issues = @project.issues
    render_issues_list
  end

  def all_index
    project_ids = get_all_project_ids Project.accessible_by(current_ability, :membered).pluck(:id)
    @issues = Issue.where(project_id: project_ids)
    render_issues_list
  end

  def user_index
    project_ids = get_all_project_ids current_user.projects.pluck(:id)
    @issues = Issue.where(project_id: project_ids)
    render_issues_list
  end

  def group_index
    project_ids = @group.projects.pluck(:id)
    project_ids = Project.accessible_by(current_ability, :membered).where(id: project_ids).pluck(:id)
    @issues = Issue.where(project_id: project_ids)
    render_issues_list
  end

  def show
    redirect_to api_v1_project_pull_request_path(@project.id, @issue.serial_id) if @issue.pull_request
    respond_to do |format|
      format.json
    end
  end

  def create
    @issue.user = current_user
    @issue.assignee = nil if cannot?(:write, @project)
    create_subject @issue
  end

  def update
    unless can?(:write, @project)
      params.delete :update_labels
      [:assignee_id, :labelings, :labelings_attributes].each do |k|
        params[:issue].delete k
      end if params[:issue]
    end
    @issue.labelings.destroy_all if params[:update_labels]
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
      labels = params[:labels].split(',').map {|e| e.strip}.select {|e| e.present?}
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

  def get_all_project_ids default_project_ids
    project_ids = []
    if ['created', 'all'].include? params[:filter]
      # add own issues
      project_ids = Project.accessible_by(current_ability, :show).joins(:issues).
                            where(issues: {user_id: current_user.id}).pluck('projects.id')
    end
    project_ids |= default_project_ids
  end
end
