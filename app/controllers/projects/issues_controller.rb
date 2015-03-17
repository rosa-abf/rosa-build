class Projects::IssuesController < Projects::BaseController
  NON_RESTFUL_ACTION = [:create_label, :update_label, :destroy_label]
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:index, :show] if APP_CONFIG['anonymous_access']
  load_resource :project
  load_and_authorize_resource :issue, through: :project, find_by: :serial_id, only: [:show, :edit, :update, :destroy, :new, :create, :index]
  before_action :load_and_authorize_label, only: NON_RESTFUL_ACTION
  before_action :find_collaborators, only: [:new, :create, :show, :search_collaborators]

  layout false, only: [:update, :search_collaborators]

  def index
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
        if params[:kind] == 'pull_requests'
          all_issues = @project.issues.joins(:pull_request)
        else
          all_issues = @project.issues.without_pull_requests
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
  end

  def create
    @issue.user_id = current_user.id

    unless policy(@project).write?
      @issue.assignee_id  = nil
      @issue.labelings    = []
    end
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
        unless policy(@project).write?
          params.delete :update_labels
          [:assignee_id, :labelings, :labelings_attributes].each do |k|
            params[:issue].delete k
          end if params[:issue]
        end

        if params[:issue] && status = params[:issue][:status]
          @issue.set_close(current_user) if status == 'closed'
          @issue.set_open if status == 'open'
          status = @issue.save ? 200 : 500
        else
          status = 422 unless @issue.update_attributes(params[:issue])
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

  def load_and_authorize_label
    authorize @project, :write?
    @label = Label.find(params[:label_id]) if params[:label_id]
  end
end
