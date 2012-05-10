# -*- encoding : utf-8 -*-
class Projects::PullRequestsController < Projects::BaseController
  before_filter :authenticate_user!
  load_resource :project
  #load_and_authorize_resource :pull_request, :through => :project, :find_by => :serial_id #FIXME Disable for development

  def index
  end

  def new
    @pull = PullRequest.default_base_project(@project).pull_requests.new
    #@pull.build_issue
    @pull.issue = @project.issues.new
    @pull.head_project = @project

    @pull.base_ref = @pull.base_project.default_branch
    @pull.head_ref = params[:treeish].presence || @pull.head_project.default_branch

    @pull.check

    repo = Git::Repository.new(@pull.path)
    @base_commit = repo.commits(@pull.base_ref).first
    @head_commit = repo.commits(@pull.head_ref).first

    @diff = Grit::Repo.new(@pull.path).diff @base_commit, @head_commit
  end

  def create
    @pull = @project.pull_requests.new(params[:pull_request]) # FIXME need validation!
    @pull.issue.user, @pull.issue.project = current_user, @pull.base_project
    @pull.base_ref = params[:base_ref] # FIXME need validation!
    @pull.head_ref = params[:head_ref] # FIXME need validation!

    if @pull.save
      render :index #FIXME redirect to show
    else
      render :new
    end
  end

  def update
  end

end
