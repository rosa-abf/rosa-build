class Projects::IssuesController < Projects::BaseController
  NON_RESTFUL_ACTION = [:create_label, :update_label, :destroy_label]
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:index, :show] if APP_CONFIG['anonymous_access']
  load_resource :project
  load_and_authorize_resource :issue, through: :project, find_by: :serial_id, only: [:show, :edit, :update, :destroy, :new, :create, :index]
  before_filter :load_and_authorize_label, only: NON_RESTFUL_ACTION
  before_filter :find_collaborators, only: [:new, :create, :show, :search_collaborators]

  layout false, only: [:update, :search_collaborators]

  def index(status = 200)
    @labels = params[:labels] || []
    @issues = @project.issues.without_pull_requests
    @issues = @issues.where(assignee_id: current_user.id) if @is_assigned_to_me = params[:filter] == 'assigned'
    @issues = @issues.joins(:labels).where(labels: {name: @labels}) unless @labels == []
    # Using mb_chars for correct transform to lowercase ('Русский Текст'.downcase => "Русский Текст")
    @issues = @issues.search(params[:search_issue]) if params[:search_issue] !~ /#{t('layout.issues.search')}/

    @opened_issues, @closed_issues = @issues.not_closed_or_merged, @issues.closed_or_merged
    @status = params[:status] == 'closed' ? :closed : :open
    @issues = @issues.send( (@status == :closed) ? :closed_or_merged : :not_closed_or_merged )

    @sort       = params[:sort] == 'updated' ? :updated : :created
    @direction  = params[:direction] == 'asc' ? :asc : :desc
    @issues = @issues.order("issues.#{@sort}_at #{@direction}")
    @issues = @issues.preload(:assignee, :user, :pull_request).uniq
                     .paginate per_page: 20, page: params[:page]
    if status == 200
      render 'index', layout: request.xhr? ? 'with_sidebar' : 'application'
    else
      render status: status, nothing: true
    end
  end

  def new
  end

  def create
    @issue.user_id = current_user.id

    unless can?(:write, @project)
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
  end

  def update
    unless can?(:write, @project)
      params.delete :update_labels
      [:assignee_id, :labelings, :labelings_attributes].each do |k|
        params[:issue].delete k
      end if params[:issue]
    end
    @issue.labelings.destroy_all if params[:update_labels]
    if params[:issue] && status = params[:issue][:status]
      @issue.set_close(current_user) if status == 'closed'
      @issue.set_open if status == 'open'
      render partial: 'status', status: (@issue.save ? 200 : 400)
    elsif params[:issue]
      status, message = if @issue.update_attributes(params[:issue])
        [200, view_context.markdown(@issue.body)]
      else
        [400, view_context.local_alert(@issue.errors.full_messages.join('. '))]
      end
      render inline: message, status: status
    else
      render nothing: true, status: 200
    end
  end

  # def destroy
  #   @issue.destroy
  #   flash[:notice] = t("flash.issue.destroyed")
  #   redirect_to root_path
  # end

  def create_label
    index(@project.labels.create!(name: params[:name], color: params[:color]) ? 200 : 500)
  end

  def update_label
    index(@label.update_attributes(name: params[:name], color: params[:color]) ? 200 : 500)
  end

  def destroy_label
    index((@label && @label_destroy) ? 200 : 500)
  end

  def search_collaborators
    render partial: 'search_collaborators'
  end

  private

  def load_and_authorize_label
    @label = Label.find(params[:label_id]) if params[:label_id]
    authorize! :write, @project
  end
end
