class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:root]
  skip_after_action :verify_authorized

  def root
    respond_to do |format|
      format.html { render 'pages/tour/abf-tour-project-description-1' }
    end
  end

  def activity(is_my_activity = false)
    @filter = t('feed_menu').has_key?(params[:filter].try(:to_sym)) ? params[:filter].to_sym : :all
    @activity_feeds = current_user.activity_feeds
                                  .by_project_name(params[:project_name_filter])
                                  .by_owner_uname(params[:owner_filter])
    @activity_feeds = @activity_feeds.where(kind: "ActivityFeed::#{@filter.upcase}".constantize) unless @filter == :all
    @activity_feeds = @activity_feeds.where(user_id: current_user) if @own_filter == :created
    @activity_feeds = @activity_feeds.where.not(user_id: current_user) if @own_filter == :not_created

    @activity_feeds = if is_my_activity
                        @activity_feeds.where(creator_id: current_user)
                      else
                        @activity_feeds.where.not(creator_id: current_user)
                      end

    @activity_feeds = @activity_feeds.paginate page: current_page

    respond_to do |format|
      format.html { render 'activity' }
      format.json { render 'activity' }
      format.atom
    end
  end

  def own_activity
    activity(true)
  end

  def issues
    @created_issues  = current_user.issues
    @assigned_issues = Issue.where(assignee_id: current_user.id)
    pr_ids = ProjectPolicy::Scope.new(current_user, Project).membered.uniq.pluck(:id)
    @all_issues = Issue.where(project_id: pr_ids)
    @created_issues, @assigned_issues, @all_issues =
      if action_name == 'issues'
        [@created_issues.without_pull_requests,
         @assigned_issues.without_pull_requests,
         @all_issues.without_pull_requests]
      else
        [@created_issues.joins(:pull_request),
         @assigned_issues.joins(:pull_request),
         @all_issues.joins(:pull_request)]
      end

    case params[:filter]
    when 'created'
      @issues = @created_issues
    when 'assigned'
      @issues = @assigned_issues
    else
      params[:filter] = 'all' # default
      @issues = @all_issues
    end
    @filter = params[:filter]
    @opened_issues, @closed_issues = @issues.not_closed_or_merged, @issues.closed_or_merged

    @status = params[:status] == 'closed' ? :closed : :open
    @issues = @issues.send( (@status == :closed) ? :closed_or_merged : :not_closed_or_merged )

    @sort       = params[:sort] == 'updated' ? :updated : :created
    @direction  = params[:direction] == 'asc' ? :asc : :desc
    @issues = @issues.order("issues.#{@sort}_at #{@direction}")
                     .includes(:assignee, :user, :pull_request).uniq
                     .paginate page: current_page

    respond_to do |format|
      format.html { render 'activity' }
      format.json { render 'issues' }
    end
  end

  def pull_requests
    issues
  end

  def get_owners_list
    if params[:term].present?
      users   =  User.opened.search(params[:term]).pluck(:uname).first(5)
      groups  = Group.opened.search(params[:term]).pluck(:uname).first(5)
      @owners = users | groups

    end
    respond_to do |format|
      format.json {}
    end
  end

  def get_project_names_list
    if params[:term].present?
      @projects = ProjectPolicy::Scope.new(current_user, Project).membered

      @projects = @projects.where(owner_uname: params[:owner_uname]) if params[:owner_uname].present?
      @projects = @projects.by_name("%#{params[:term]}%")
                           .distinct
                           .pluck(:name)
                           .first(10)
    end
    respond_to do |format|
      format.json {}
    end
  end
end
