# -*- encoding : utf-8 -*-
class Projects::PullRequestsController < Projects::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:index, :show] if APP_CONFIG['anonymous_access']
  load_resource :project

  load_and_authorize_resource :issue, :through => :project, :find_by => :serial_id, :parent => false, :except => :autocomplete_base_project
  before_filter :load_pull, :except => :autocomplete_base_project

  def new
    base_project = (Project.find(params[:base_project_id]) if params[:base_project_id]) || PullRequest.default_base_project(@project)
    authorize! :read, base_project

    @pull = base_project.pull_requests.new
    @pull.issue = base_project.issues.new
    set_attrs

    if PullRequest.check_ref(@pull, 'base', @pull.base_ref) && PullRequest.check_ref(@pull, 'head', @pull.head_ref)
      flash[:warning] = @pull.errors.full_messages.join('. ')
    else
      @pull.check(false) # don't make event transaction
      if @pull.already?
        @pull.destroy
        flash[:warning] = I18n.t('projects.pull_requests.up_to_date', :base_ref => @pull.base_ref, :head_ref => @pull.head_ref)
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
    base_project = Project.find(params[:base_project_id])
    authorize! :read, base_project

    @pull = base_project.pull_requests.new pull_params
    @pull.issue.user, @pull.issue.project, @pull.head_project = current_user, base_project, @project

    if @pull.valid?
      @pull.check(false) # don't make event transaction
      if @pull.already?
        @pull.destroy
        flash[:error] = I18n.t('projects.pull_requests.up_to_date', :base_ref => @pull.base_ref, :head_ref => @pull.head_ref)
        render :new
      else
        @pull.save
        redirect_to project_pull_request_path(@pull.base_project, @pull)
      end
    else
      flash[:error] = t('flash.pull_request.save_error')
      flash[:warning] = @pull.errors.full_messages.join('. ')

      if @pull.errors.try(:messages) && @pull.errors.messages[:base_ref].nil? && @pull.errors.messages[:head_ref].nil?
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
      redirect_to project_pull_request_path(@pull.base_project, @pull)
    else
      render :nothing => true, :status => (@pull.update_attributes(params[:pull_request]) ? 200 : 500), :layout => false
    end
  end

  def merge
    @pull.check
    unless @pull.merge!(current_user)
      flash[:error] = t('flash.pull_request.save_error')
      flash[:warning] = @pull.errors.full_messages.join('. ')
    end
    redirect_to project_pull_request_path(@pull.base_project, @pull)
  end

  def show
    load_diff_commits_data
  end

  def autocomplete_base_project
    #Maybe slow? ILIKE?
    items = Project.accessible_by(current_ability, :membered)
    items << PullRequest.default_base_project(@project)
    items.select! {|e| Regexp.new(params[:term].downcase).match(e.name.downcase) && e.repo.branches.count > 0}
    items.uniq!
    render :json => json_for_autocomplete_base(items)#, :fullname, [:branches])
  end

  protected

  def pull_params
    @pull_params ||= params[:pull_request].presence
  end

  def json_for_autocomplete_base items
    items.collect do |project|
      hash = {"id" => project.id.to_s, "label" => project.fullname, "value" => project.fullname}
      hash[:refs] = project.repo.branches_and_tags.map &:name
      hash
    end
  end

  def load_pull
    if params[:action].to_sym != :index
      @pull = @project.pull_requests.where(:issue_id => @issue.id).first
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

  def set_attrs
    if pull_params && pull_params[:issue_attributes]
      @pull.issue.title = pull_params[:issue_attributes][:title].presence
      @pull.issue.body = pull_params[:issue_attributes][:body].presence
    end
    @pull.head_project = @project
    @pull.base_ref = (pull_params[:base_ref].presence if pull_params) || @pull.base_project.default_branch
    @pull.head_ref = params[:treeish].presence || (pull_params[:head_ref].presence if pull_params) || @pull.head_project.default_branch
  end
end
