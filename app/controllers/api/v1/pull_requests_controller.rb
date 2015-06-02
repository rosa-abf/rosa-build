class Api::V1::PullRequestsController < Api::V1::BaseController
  include Api::V1::Issueable

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: %i(show index group_index commits files) if APP_CONFIG['anonymous_access']

  before_action :load_group,   only:   %i(group_index)
  before_action :load_project, except: %i(all_index user_index)
  before_action :load_issue,   only:   %i(show index commits files merge update)
  before_action :load_pull,    only:   %i(show index commits files merge update)

  def index
    @pulls = @project.pull_requests
    @pulls_url = api_v1_project_pull_requests_path(@project, format: :json)
    render_pulls_list
  end

  def all_index
    authorize :pull_request, :index?
    project_ids = get_all_project_ids membered_projects.pluck(:id)
    @pulls = PullRequest.where('pull_requests.to_project_id IN (?)', project_ids)
    @pulls_url = api_v1_pull_requests_path format: :json
    render_pulls_list
  end

  def user_index
    authorize :pull_request, :index?
    project_ids = get_all_project_ids current_user.projects.pluck(:id)
    @pulls = PullRequest.where('pull_requests.to_project_id IN (?)', project_ids)
    @pulls_url = pull_requests_api_v1_user_path format: :json
    render_pulls_list
  end

  def group_index
    project_ids = @group.projects.pluck(:id)
    project_ids = membered_projects.where(id: project_ids).pluck(:id)
    @pulls = PullRequest.where(to_project_id: project_ids)
    @pulls_url = pull_requests_api_v1_group_path
    render_pulls_list
  end

  def show
    redirect_to api_v1_project_issue_path(@project.id, @issue.serial_id) and return if @pull.nil?
  end

  def create
    from_project   = Project.find_by(id: pull_params[:from_project_id])
    from_project ||= @project
    authorize from_project, :show?

    @pull = @project.pull_requests.build
    @pull.build_issue title: pull_params[:title], body: pull_params[:body]
    @pull.from_project            = from_project
    @pull.to_ref, @pull.from_ref  = pull_params[:to_ref], pull_params[:from_ref]
    @pull.issue.assignee_id       = pull_params[:assignee_id] if policy(@project).write?
    @pull.issue.user, @pull.issue.project = current_user, @project
    @pull.issue.new_pull_request  = true
    render_validation_error(@pull, "#{@pull.class.name} has not been created") && return unless @pull.valid?

    authorize @pull
    @pull.save # set pull id
    @pull.reload
    @pull.check(false) # don't make event transaction
    if @pull.already?
      @pull.destroy
      error_message = I18n.t('projects.pull_requests.up_to_date', to_ref: @pull.to_ref, from_ref: @pull.from_ref)
      render_json_response(@pull, error_message, 422)
    else
      @pull.send(@pull.status == 'blocked' ? 'block' : @pull.status)
      render_json_response @pull, "#{@pull.class.name} has been created successfully"
    end
  end

  def update
    @pull = @project.pull_requests.includes(:issue).where(issues: {serial_id: params[:id]}).first
    authorize @pull

    if pull_params.present?
      attrs = subject_params(PullRequest)
      attrs.merge!(assignee_id: pull_params[:assignee_id]) if policy(@project).write?

      if action = %w(close reopen).find{ |s| s == pull_params[:status] }
        if @pull.send("can_#{action}?")
          @pull.set_user_and_time current_user
          need_check = true if action == 'reopen' && @pull.valid?
        end
      end
    end

    class_name = @pull.class.name
    if @pull.issue.update_attributes(attrs)
      @pull.send(action) if action.present?
      @pull.check if need_check
      render_json_response @pull, "#{class_name} has been updated successfully"
    else
      render_validation_error @pull, "#{class_name} has not been updated"
    end
  end

  def commits
    authorize @pull
    @commits = @pull.repo.commits_between(@pull.to_commit, @pull.from_commit).paginate(paginate_params)
  end

  def files
    authorize @pull
    @stats = @pull.diff_stats.zip(@pull.diff).paginate(paginate_params)
  end

  def merge
    authorize @pull
    class_name = @pull.class.name
    if @pull.merge!(current_user)
      render_json_response @pull, "#{class_name} has been merged successfully"
    else
      render_validation_error @pull, "#{class_name} has not been merged"
    end
  end

  private

  # Private: before_action hook which loads PullRequest.
  def load_pull
    @pull = @issue.pull_request
    authorize @pull, :show? if @pull
  end

  def render_pulls_list
    @pulls = @pulls.includes(issue: [:user, :assignee])
    if params[:status] == 'closed'
      @pulls = @pulls.closed_or_merged
    else
      @pulls = @pulls.not_closed_or_merged
    end

    if action_name == 'index' && params[:assignee].present?
      case params[:assignee]
      when 'none'
        @pulls = @pulls.where('issues.assigned_id IS NULL')
      when '*'
        @pulls = @pulls.where('issues.assigned_id IS NOT NULL')
      else
        @pulls = @pulls.where('assignees_issues.uname = ?', params[:assignee])
      end
    end

    if %w[all_index user_index group_index].include?(action_name)
      case params[:filter]
      when 'created'
        @pulls = @pulls.where('issues.user_id = ?', current_user.id)
      when 'all'
      else
        @pulls = @pulls.where('issues.assignee_id = ?', current_user.id)
      end
    else
      @pulls.where('users.uname = ?', params[:creator]) if params[:creator].present?
    end

    sort = params[:sort] == 'updated' ? 'issues.updated_at' : 'issues.created_at'
    direction = params[:direction] == 'asc' ? 'ASC' : 'DESC'
    @pulls = @pulls.order("#{sort} #{direction}")

    @pulls = @pulls.where('issues.created_at >= to_timestamp(?)', params[:since]) if params[:since] =~ /\A\d+\z/
    @pulls = @pulls.paginate(paginate_params)

    render :index
  end

  def pull_params
    @pull_params ||= params[:pull_request] || {}
  end
end
