# -*- encoding : utf-8 -*-
class Projects::PullRequestsController < Projects::BaseController
  before_filter :authenticate_user!
  load_resource :project
  #load_and_authorize_resource :pull_request, :through => :project, :find_by => :serial_id #FIXME Disable for development
  load_resource :pull_request

  def index
  end

  def new
    @pull = PullRequest.default_base_project(@project).pull_requests.new
    #@pull.build_issue
    @pull.issue = @project.issues.new
    @pull.head_project = @project

    @pull.base_ref = @pull.base_project.default_branch
    @pull.head_ref = params[:treeish].presence || @pull.head_project.default_branch
    if @pull.save
      @pull.check
      if @pull.state == 'already'
        record.errors.add(:head_ref, I18n.t('projects.pull_requests.up_to_date', :base_ref => record.base_ref, :head_ref => record.head_ref))
        flash[:error] = t('flash.pull_request.create_error')
        flash[:warning] = @pull.errors.full_messages.join('. ')
      end
      repo = Git::Repository.new(@pull.path)
      @base_commit = repo.commits(@pull.base_ref).first
      @head_commit = repo.commits(@pull.head_branch).first
      @diff = Grit::Repo.new(@pull.path).diff @base_commit, @head_commit
    else
      flash[:error] = t('flash.pull_request.create_error')
      flash[:warning] = @pull.errors.full_messages.join('. ')
    end
  end

  def create
    @pull = @project.pull_requests.new(params[:pull_request]) # FIXME need validation!
    @pull.issue.user, @pull.issue.project = current_user, @pull.base_project
    @pull.base_project, @pull.head_project = PullRequest.default_base_project(@project), @project
    #@pull.base_ref = params[:base_ref] # FIXME need validation!
    #@pull.head_ref = params[:head_ref] # FIXME need validation!

    if @pull.save
      @pull.check
      puts "!!!!!!!!!!!!!!!!!!!!!!!!"
      puts "pull state is #{@pull.state}"
      if @pull.state == 'already'
        @pull.destroy

        @pull.errors.add(:head_ref, I18n.t('projects.pull_requests.up_to_date', :base_ref => @pull.base_ref, :head_ref => @pull.head_ref))
        flash[:notice] = t('flash.pull_request.saved')
        flash[:warning] = @pull.errors.full_messages.join('. ')
        render :new
      else
        redirect_to project_pull_request_path(@project, @pull)
      end
    else
      flash[:error] = t('flash.pull_request.save_error')
      flash[:warning] = @pull.errors.full_messages.join('. ')
      render :new
    end
  end

  def update
  end

  def merge
    @pull_request.check
    @pull_request.merge! current_user
    redirect_to :show
  end

  def show
    @pull = @pull_request
    repo = Git::Repository.new(@pull.path)
    @base_commit = repo.commits(@pull.base_ref).first
    @head_commit = repo.commits(@pull.head_branch).first

    @diff = Grit::Repo.new(@pull.path).diff @base_commit, @head_commit
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
end
