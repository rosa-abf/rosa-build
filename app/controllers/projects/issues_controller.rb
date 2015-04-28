class Projects::IssuesController < Projects::BaseController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index, :show] if APP_CONFIG['anonymous_access']
  before_action :load_issue,               only: %i(show edit update destroy)
  before_action :load_and_authorize_label, only: %i(create_label update_label destroy_label)
  before_action :find_collaborators,       only: :search_collaborators

  layout false, only: [:update, :search_collaborators]

  def index
    raise Pundit::NotAuthorizedError unless @project.has_issues?

    params[:kind]      = params[:kind] == 'pull_requests' ? 'pull_requests' : 'issues'
    params[:filter]    = params[:filter].in?(['created', 'assigned']) ? params[:filter] : 'all'
    params[:sort]      = params[:sort] == 'submitted' ? 'submitted' : 'updated'
    params[:direction] = params[:direction] == 'asc' ? :asc : :desc
    params[:status]    = params[:status] == 'closed' ? :closed : :open
    if !params[:labels].is_a?(Array) || params[:labels].blank?
      params[:labels] = []
    end

    respond_to do |format|
      format.html { render 'index' }
      format.json do
        all_issues =
          if params[:kind] == 'pull_requests'
            @project.issues.joins(:pull_request)
          else
            @project.issues.without_pull_requests
          end

        @all_issues        = all_issues
        if current_user
          @created_issues  = all_issues.where(user_id: current_user)
          @assigned_issues = all_issues.where(assignee_id: current_user)
        end

        case params[:filter]
        when 'created'
          @issues = @created_issues
        when 'assigned'
          @issues = @assigned_issues
        else
          @issues = all_issues
        end

        if params[:labels].is_a?(Array) && params[:labels].present?
          @issues = @issues.joins(:labels).where(labels: {name: params[:labels]})
        end

        @opened_issues, @closed_issues = @issues.not_closed_or_merged, @issues.closed_or_merged
        @issues = @issues.send( params[:status] == :closed ? :closed_or_merged : :not_closed_or_merged )

        if params[:sort] == 'submitted'
          @issues = @issues.order(created_at: params[:direction])
        else
          @issues = @issues.order(updated_at: params[:direction])
        end

        @issues = @issues.includes(:assignee, :user, :pull_request).uniq
                         .paginate(page: current_page)

        render 'index'
      end
    end
  end

  def pull_requests
    params[:kind] = 'pull_requests'
    index
  end

  def labels
    render partial: 'projects/issues/labels.json', locals: {project: @project}, layout: false
  end

  def new
    authorize @issue = @project.issues.build
  end

  def create
    @issue      = @project.issues.new
    @issue.assign_attributes(issue_params)
    @issue.user = current_user

    authorize @issue
    if @issue.save
      @issue.subscribe_creator(current_user.id)
      flash[:notice] = I18n.t("flash.issue.saved")
      redirect_to project_issues_path(@project)
    else
      flash[:error] = I18n.t("flash.issue.save_error")
      render action: :new
    end
  end

  def show
    redirect_to project_pull_request_path(@project, @issue.pull_request) if @issue.pull_request
    @commentable = @issue
  end

  def update
    respond_to do |format|
      format.html { render nothing: true, status: 200 }

      format.json {
        status = 200
        if params[:issue] && status = params[:issue][:status]
          @issue.set_close(current_user) if status == 'closed'
          @issue.set_open if status == 'open'
          status = @issue.save ? 200 : 500
        else
          status = 422 unless @issue.update_attributes(issue_params)
        end
        render status: status
      }
    end
  end

  # def destroy
  #   @issue.destroy
  #   flash[:notice] = t("flash.issue.destroyed")
  #   redirect_to root_path
  # end

  def create_label
    @label = @project.labels.new(name: params[:name], color: params[:color])
    respond_to do |format|
      if @label.save
        format.json { render partial: 'labels', locals: {project: @project} }
      else
        format.json { render text: @label.errors.full_messages, status: 422 }
      end
    end
  end

  def update_label
    respond_to do |format|
      if @label.update_attributes(name: params[:name], color: params[:color])
        format.json { render partial: 'labels', locals: {project: @project} }
      else
        format.json { render text: @label.errors.full_messages, status: 422 }
      end
    end
  end

  def destroy_label
    respond_to do |format|
      if @label.destroy
        format.json { render partial: 'labels', locals: {project: @project} }
      else
        format.json { render json: @label.errors.full_messages, status: 422 }
      end
    end
  end

  def search_collaborators
  end

  private

  def issue_params
    subject_params(Issue, @issue)
  end

  # Private: before_action hook which loads Issue.
  def load_issue
    authorize @issue = @project.issues.find_by!(serial_id: params[:id])
  end

  # Private: before_action hook which loads Label.
  def load_and_authorize_label
    authorize @project, :write?
    @label = @project.labels.find(params[:label_id]) if params[:label_id]
  end
end
