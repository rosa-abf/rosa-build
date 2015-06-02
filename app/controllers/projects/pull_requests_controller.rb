class Projects::PullRequestsController < Projects::BaseController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index, :show] if APP_CONFIG['anonymous_access']

  before_action :load_issue,         except: %i(index autocomplete_to_project new create)
  before_action :load_pull,          except: %i(index autocomplete_to_project new create)

  def new
    to_project = find_destination_project(false)
    authorize to_project, :show?

    @pull  = to_project.pull_requests.new
    @issue = @pull.issue = to_project.issues.new
    set_attrs

    authorize @pull
    if PullRequest.check_ref(@pull, 'to', @pull.to_ref) && PullRequest.check_ref(@pull, 'from', @pull.from_ref) || @pull.uniq_merge
      flash.now[:warning] = @pull.errors.full_messages.join('. ')
    else
      @pull.check(false) # don't make event transaction
      if @pull.already?
        @pull.destroy
        flash.now[:warning] = I18n.t('projects.pull_requests.up_to_date', to_ref: @pull.to_ref, from_ref: @pull.from_ref)
      else
        load_diff_commits_data
      end
    end
  end

  def create
    unless pull_params
      redirect :back
    end
    to_project = find_destination_project
    authorize to_project, :show?

    @pull  = to_project.pull_requests.build pull_params
    @issue = @pull.issue
    @pull.issue.assignee_id = (params[:issue] || {})[:assignee_id] if policy(to_project).write?
    @pull.issue.user, @pull.issue.project, @pull.from_project = current_user, to_project, @project
    @pull.from_project_owner_uname  = @pull.from_project.owner.uname
    @pull.from_project_name         = @pull.from_project.name
    @pull.issue.new_pull_request    = true

    authorize @pull
    if @pull.valid? # FIXME more clean/clever logics
      @pull.save # set pull id
      @pull.reload
      @pull.check(false) # don't make event transaction
      if @pull.already?
        @pull.destroy
        flash.now[:error] = I18n.t('projects.pull_requests.up_to_date', to_ref: @pull.to_ref, from_ref: @pull.from_ref)
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

  def merge
    authorize @pull
    status = @pull.merge!(current_user) ? 200 : 422
    render nothing: true, status: status
  end

  def update
    authorize @pull
    status = 422
    if (action = params[:pull_request_action]) && %w(close reopen).include?(params[:pull_request_action])
      if @pull.send("can_#{action}?")
        @pull.set_user_and_time current_user
        @pull.send(action)
        @pull.check if @pull.open?
        status = 200
      end
    end
    render nothing: true, status: status
  end

  def show
    if @pull.nil?
      redirect_to project_issue_path(@project, @issue)
      return
    end

    load_diff_commits_data

    if params[:get_activity] == 'true'
      render partial: 'activity', layout: false
    elsif params[:get_diff]  == 'true'
      render partial: 'diff_tab', layout: false
    elsif params[:get_commits]  == 'true'
      render partial: 'commits_tab', layout: false
    end
  end

  def autocomplete_to_project
    items = []
    term = params[:query].to_s.strip.downcase
    [ Project.where(id: @project.pull_requests.last.try(:to_project_id)),
      @project.ancestors,
      ProjectPolicy::Scope.new(current_user, Project).membered
    ].each do |p|
      items.concat p.by_owner_and_name(term)
    end
    items = items.uniq{|i| i.id}.select{|e| e.repo.branches.count > 0}
    render json: json_for_autocomplete_base(items)
  end

  protected

  # Private: before_action hook which loads Issue.
  def load_issue
    @issue = @project.issues.find_by!(serial_id: params[:id])
  end

  # Private: before_action hook which loads PullRequest.
  def load_pull
    @pull = @issue.pull_request
    authorize @pull, :show? if @pull
  end

  def pull_params
    @pull_params ||= subject_params(PullRequest).presence
  end

  def json_for_autocomplete_base items
    items.collect do |project|
      {id: project.id.to_s, name: project.name_with_owner}
    end
  end

  def load_diff_commits_data
    @commits = @pull.repo.commits_between(@pull.to_commit, @pull.from_commit)
    @total_commits = @commits.count
    @commits = @commits.last(100)

    @stats = @pull.diff_stats
    @comments, @commentable = @issue.comments, @issue
  end

  def find_destination_project bang=true
    project = Project.find_by_owner_and_name params[:to_project]
    raise ActiveRecord::RecordNotFound if bang && !project
    project || @project.pull_requests.last.try(:to_project) || @project.root
  end

  def set_attrs
    if pull_params && pull_params[:issue_attributes]
      @pull.issue.title = pull_params[:issue_attributes][:title].presence
      @pull.issue.body = pull_params[:issue_attributes][:body].presence
    end
    @pull.from_project = @project
    @pull.to_ref = (pull_params[:to_ref].presence if pull_params) || @pull.to_project.default_head
    @pull.from_ref = params[:treeish].presence || (pull_params[:from_ref].presence if pull_params) || @pull.from_project.default_head(params[:treeish])
    @pull.from_project_owner_uname = @pull.from_project.owner.uname
    @pull.from_project_name = @pull.from_project.name
  end
end
