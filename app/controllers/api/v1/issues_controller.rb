# -*- encoding : utf-8 -*-
class Api::V1::IssuesController < Api::V1::BaseController
  respond_to :json

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show] if APP_CONFIG['anonymous_access']

  load_resource :group, :only => :group_index, :find_by => :id, :parent => false
  load_resource :project
  load_and_authorize_resource :issue, :through => :project, :find_by => :serial_id, :only => [:show, :update, :destroy, :create, :index]

  def index
    @issues = @project.issues
    render_issues_list
  end

  def all_index
    project_ids = get_all_project_ids Project.accessible_by(current_ability, :membered).uniq.pluck(:id)
    @issues = Issue.where('issues.project_id IN (?)', project_ids)
    render_issues_list
  end

  def user_index
    project_ids = get_all_project_ids current_user.projects.select('distinct projects.id').pluck(:id)
    @issues = Issue.where('issues.project_id IN (?)', project_ids)
    render_issues_list
  end

  def group_index
    project_ids = @group.projects.select('distinct projects.id').pluck(:id)
    project_ids = Project.accessible_by(current_ability, :membered).where(:id => project_ids).uniq.pluck(:id)
    @issues = Issue.where(:project_id => project_ids)
    render_issues_list
  end

  def show
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
    if params[:status] == 'closed'
      @issues = @issues.closed
    else
      @issues = @issues.opened
    end

    if action_name == 'index' && params[:assignee].present?
      case params[:assignee]
      when 'none'
        @issues = @issues.where(:assigned_id => nil)
      when '*'
        @issues = @issues.where('issues.assigned_id IS NOT NULL')
      else
        @issues = @issues.where('issues.assignees_issues.uname = ?', params[:assignee])
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

    @issues = @issues.where('issues.created_at >= to_timestamp(?)', params[:since]) if params[:since] =~ /\A\d+\z/
    @issues.paginate(paginate_params)
    render :index
  end

  def get_all_project_ids default_project_ids
    project_ids = []
    if ['created', 'all'].include? params[:filter]
      # add own issues
      project_ids = Project.accessible_by(current_ability, :show).joins(:issues).
                            where(:issues => {:user_id => current_user.id}).uniq.pluck('projects.id')
    end
    project_ids |= default_project_ids
  end
end
