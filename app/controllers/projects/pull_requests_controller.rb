# -*- encoding : utf-8 -*-
class Projects::PullRequestsController < Projects::BaseController
  SKIP = [:autocomplete_base_project_name, :autocomplete_head_project_name, :autocomplete_base_ref, :autocomplete_head_ref]
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index, :show] if APP_CONFIG['anonymous_access']
  load_resource :project

  load_and_authorize_resource :issue, :through => :project, :find_by => :serial_id, :parent => false, :except => SKIP
  before_filter :load_pull, :except => SKIP

  def new
    @pull = PullRequest.default_base_project(@project).pull_requests.new
    @pull.issue = @project.issues.new
    if params[:pull_request] && params[:pull_request][:issue_attributes]
      @pull.issue.title = params[:pull_request][:issue_attributes][:title].presence
      @pull.issue.body = params[:pull_request][:issue_attributes][:body].presence
    end
    @pull.head_project = @project
    @pull.base_ref = (params[:pull_request][:base_ref].presence if params[:pull_request]) || @pull.base_project.default_branch
    @pull.head_ref = params[:treeish].presence || (params[:pull_request][:head_ref].presence if params[:pull_request]) || @pull.head_project.default_branch
    @pull.check(false) # don't make event transaction
    if @pull.status == 'already'
      @pull.destroy
      flash[:warning] = I18n.t('projects.pull_requests.up_to_date', :base_ref => @pull.base_ref, :head_ref => @pull.head_ref)
    else
      load_diff_commits_data
    end
  end

  def create
    @pull = @project.pull_requests.new(params[:pull_request])
    @pull.issue.user, @pull.issue.project = current_user, @pull.base_project
    @pull.base_project, @pull.head_project = PullRequest.default_base_project(@project), @project

    if @pull.save
      @pull.check(false) # don't make event transaction
      if @pull.status == 'already'
        @pull.destroy
        flash[:error] = I18n.t('projects.pull_requests.up_to_date', :base_ref => @pull.base_ref, :head_ref => @pull.head_ref)
        render :new
      else
        @pull.save
        redirect_to project_pull_request_path(@project, @pull)
      end
    else
      flash[:error] = t('flash.pull_request.save_error')
      flash[:warning] = @pull.errors.full_messages.join('. ')
      render :new
    end
  end

  def update
    render :nothing => true, :status => (@pull.update_attributes(params[:pull_request]) ? 200 : 500), :layout => false
  end

  def merge
    @pull.check
    load_diff_commits_data
    unless @pull.merge!(current_user)
      flash[:error] = t('flash.pull_request.save_error')
      flash[:warning] = @pull.errors.full_messages.join('. ')
    end
    render :show
  end

  def show
    load_diff_commits_data
  end

  def autocomplete_base_project_name
    items = Project.accessible_by(current_ability, :membered)
    items << PullRequest.default_base_project(@project)
    items.uniq!
    render :json => json_for_autocomplete(items, 'full_name')
  end

  def autocomplete_head_project_name
    items = Project.accessible_by(current_ability, :membered)
    render :json => json_for_autocomplete(items, 'full_name')
  end

  def autocomplete_base_ref
    project = PullRequest.default_base_project(@project)
    items = (project.branches + project.tags).select {|e| Regexp.new(params[:term].downcase).match e.name.downcase}
    render :json => json_for_autocomplete_ref(items)
  end

  def autocomplete_head_ref
    items = (@project.branches + @project.tags).select {|e| Regexp.new(params[:term].downcase).match e.name.downcase}
    render :json => json_for_autocomplete_ref(items)
  end

  protected

  def json_for_autocomplete_ref(items)
    items.collect do |item|
      {"id" => item.name, "label" => item.name, "value" => item.name}
    end
  end

  def load_pull
    @issue ||= @issues.first #FIXME!
    if params[:action].to_sym != :index
      @pull = @project.pull_requests.joins(:issue).where(:issues => {:id => @issue.id}).readonly(false).first
    else
      @pull_requests = @project.pull_requests
    end
  end

  def load_diff_commits_data
    repo = Grit::Repo.new(@pull.path)
    @base_commit = @pull.common_ancestor
    @head_commit = repo.commits(@pull.head_branch).first

    @commits = repo.commits_between repo.commits(@pull.base_ref).first, @head_commit

    @diff = @pull.diff repo, @base_commit, @head_commit
    @stats = @pull.diff_stats repo, @base_commit, @head_commit
  end
end
