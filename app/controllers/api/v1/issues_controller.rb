# -*- encoding : utf-8 -*-
class Api::V1::IssuesController < Api::V1::BaseController
  respond_to :json

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :group, :only => :group_index
  load_resource :project
  load_and_authorize_resource :issue, :through => :project, :find_by => :serial_id, :only => [:show, :update, :destroy, :create, :index]

  def index
    @issues = @project.issues
    render_issues_list
  end

  def all_index
    project_ids = Project.accessible_by(current_ability, :membered).pluck(:id)
    @issues = Issue.where('issues.project_id IN (?) OR issues.assignee_id = ? OR issues.user_id = ?',
                          project_ids, current_user, current_user)
    render_issues_list
  end

  def user_index
    project_ids = current_user.projects.pluck(:id)
    @issues = Issue.where('issues.project_id IN (?) OR issues.assignee_id = ? OR issues.user_id = ?',
                          project_ids, current_user, current_user)
    render_issues_list
  end

  def group_index
    project_ids = @group.projects.pluck(:id)
    @issues = Issue.where(:project_id => project_ids)
    render_issues_list
  end

  def show
    respond_with @issue
  end

  def create
    @issue.user = current_user
    create_subject @issue
  end

  def update
    update_subject @issue
  end

  def destroy
    destroy_subject @issue
  end

  private

  def render_issues_list
    @issues = @issues.includes(:user, :assignee, :labels).without_pull_requests
    @issues = @issues.opened if params[:status] == 'open'
    @issues = @issues.closed if params[:status] == 'closed'

    if action_name == 'index' && params[:assignee].present?
      case params[:assignee]
      when 'none'
        @issues = @issues.where(:assigned_id => nil)
      when '*'
        @issues = @issues.where('assigned_id IS NOT NULL')
      else
        @issues = @issues.where('assignees_issues.uname = ?', params[:assignee])
      end
    end

    if %w[all_index user_index group_index].include?(action_name)
      case params[:filter]
      when 'created'
        @issues = @issues.where(:user_id => current_user)
      when 'all'
      else
        @issues = @issues.where(:assignee_id => current_user)
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

    @issues = @issues.where('created_at >= to_timestamp(?)', params[:since]) if params[:since] =~ /\A\d+\z/
    @issues.paginate(paginate_params)
    render 'index'
  end

  def render_json(action_name, action_method = nil)
    if @build_list.try("can_#{action_name}?") && @build_list.send(action_method || action_name)
      render_json_response @build_list, t("layout.build_lists.#{action_name}_success")
    else
      render_validation_error @build_list, t("layout.build_lists.#{action_name}_fail")
    end
  end
end
