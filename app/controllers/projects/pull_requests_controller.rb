# -*- encoding : utf-8 -*-
class Projects::PullRequestsController < Projects::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index, :show] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource :project

  load_resource :issue, :through => :project, :find_by => :serial_id, :parent => false, :except => [:index, :autocomplete_to_project]
  load_and_authorize_resource :instance_name => :pull, :through => :issue, :singleton => true, :except => [:index, :autocomplete_to_project]

  def new
    to_project = find_destination_project(false)
    authorize! :read, to_project

    @pull = to_project.pull_requests.new
    @pull.issue = to_project.issues.new
    set_attrs

    if PullRequest.check_ref(@pull, 'to', @pull.to_ref) && PullRequest.check_ref(@pull, 'from', @pull.from_ref) || @pull.uniq_merge
      flash.now[:warning] = @pull.errors.full_messages.join('. ')
    else
      @pull.check(false) # don't make event transaction
      if @pull.already?
        @pull.destroy
        flash.now[:warning] = I18n.t('projects.pull_requests.up_to_date', :to_ref => @pull.to_ref, :from_ref => @pull.from_ref)
      else
        load_diff_commits_data
      end
    end
  end

  def create
    unless pull_params
      raise 'expect pull_request params' # for debug
      redirect :back
    end
    to_project = find_destination_project
    authorize! :read, to_project

    @pull = to_project.pull_requests.new pull_params
    @pull.issue.user, @pull.issue.project, @pull.from_project = current_user, to_project, @project

    if @pull.valid? # FIXME more clean/clever logics
      @pull.save # set pull id
      @pull.check(false) # don't make event transaction
      if @pull.already?
        @pull.destroy
        flash.now[:error] = I18n.t('projects.pull_requests.up_to_date', :to_ref => @pull.to_ref, :from_ref => @pull.from_ref)
        render :new
      else
        @pull.send(@pull.status == 'blocked' ? 'block' : @pull.status)
        redirect_to project_pull_request_path(@pull.to_project, @pull)
      end
    else
      flash.now[:error] = t('flash.pull_request.save_error')
      flash.now[:warning] = @pull.errors.full_messages.join('. ')

      if @pull.errors.try(:messages) && @pull.errors.messages[:to_ref].nil? && @pull.errors.messages[:from_ref].nil?
        @pull.check(false) # don't make event transaction
        load_diff_commits_data
      end
      render :new
    end
  end

  def update
    if (action = params[:pull_request_action]) && %w(close reopen).include?(params[:pull_request_action])
      if @pull.send("can_#{action}?")
        @pull.set_user_and_time current_user
        @pull.send(action)
        @pull.check if @pull.open?
      end
    end
    redirect_to project_pull_request_path(@pull.to_project, @pull)
  end

  def merge
    @pull.check
    unless @pull.merge!(current_user)
      flash.now[:error] = t('flash.pull_request.save_error')
      flash.now[:warning] = @pull.errors.full_messages.join('. ')
    end
    redirect_to project_pull_request_path(@pull.to_project, @pull)
  end

  def show
    load_diff_commits_data
  end

  def index(status = 200)
    @issues_with_pull_request = @project.issues.joins(:pull_request)
    @issues_with_pull_request = @issues_with_pull_request.search(params[:search_pull_request])

    @opened_issues, @closed_issues = @issues_with_pull_request.not_closed_or_merged.count, @issues_with_pull_request.closed_or_merged.count
    if params[:status] == 'closed'
      @issues_with_pull_request, @status = @issues_with_pull_request.closed_or_merged, params[:status]
    else
      @issues_with_pull_request, @status = @issues_with_pull_request.not_closed_or_merged, 'open'
    end

    @issues_with_pull_request = @issues_with_pull_request.
      includes(:assignee, :user, :pull_request).def_order.uniq.
      paginate :per_page => 10, :page => params[:page]
    if status == 200
      render 'index', :layout => request.xhr? ? 'with_sidebar' : 'application'
    else
      render :status => status, :nothing => true
    end
  end

  def autocomplete_to_project
    items = Project.accessible_by(current_ability, :membered) | @project.ancestors
    items.select! {|e| Regexp.new(params[:term].downcase).match(e.name_with_owner.downcase) && e.repo.branches.count > 0}
    render :json => json_for_autocomplete_base(items)
  end

  protected

  def pull_params
    @pull_params ||= params[:pull_request].presence
  end

  def json_for_autocomplete_base items
    items.collect do |project|
      hash = {"id" => project.id.to_s, "label" => project.name_with_owner, "value" => project.name_with_owner}
      hash[:get_refs_url] = project_refs_list_path(project)
      hash
    end
  end

  def load_diff_commits_data
    @commits = @pull.repo.commits_between(@pull.to_commit, @pull.from_commit)
    @total_commits = @commits.count
    @commits = @commits.last(100)

    @diff, @stats = @pull.diff, @pull.diff_stats
    @comments, @commentable = @issue.comments, @issue
  end

  def find_destination_project bang=true
    args = params[:to_project].try(:split, '/') || []
    project = (args.length == 2) ? Project.find_by_owner_and_name(*args) : nil
    raise ActiveRecord::RecordNotFound if bang && !project
    project || @project
  end

  def set_attrs
    if pull_params && pull_params[:issue_attributes]
      @pull.issue.title = pull_params[:issue_attributes][:title].presence
      @pull.issue.body = pull_params[:issue_attributes][:body].presence
    end
    @pull.from_project = @project
    @pull.to_ref = (pull_params[:to_ref].presence if pull_params) || @pull.to_project.default_branch
    @pull.from_ref = params[:treeish].presence || (pull_params[:from_ref].presence if pull_params) || @pull.from_project.default_branch
  end
end
