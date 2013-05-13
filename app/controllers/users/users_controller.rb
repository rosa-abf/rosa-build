# -*- encoding : utf-8 -*-
class Users::UsersController < Users::BaseController
  skip_before_filter :authenticate_user!, :only => [:allowed, :check, :discover]
  before_filter :find_user_by_key, :only => [:allowed, :discover]

  def allowed
    owner_name, project_name = params[:project].split '/'
    project = Project.find_by_owner_and_name!(owner_name, project_name ? project_name : '!')
    action = case params[:action_type]
                  when 'git-upload-pack'
                    then :read
                  when 'git-receive-pack'
                    then :write
                  end
    render :inline => (!@user.access_locked? && Ability.new(@user).can?(action, project)).to_s
  end

  def check
    render :nothing => true
  end

  def discover
    render :json => {:name => @user.name}.to_json
  end

  def issues
    @created_issues  = current_user.issues
    @assigned_issues = Issue.where(:assignee_id => current_user.id)
    pr_ids = Project.accessible_by(current_ability, :membered).uniq.pluck(:id)
    @all_issues = Issue.where(:project_id => pr_ids)
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
    @opened_issues, @closed_issues = @issues.not_closed_or_merged.count, @issues.closed_or_merged.count

    @status = params[:status] == 'closed' ? :closed : :open
    @issues = @issues.send( (@status == :closed) ? :closed_or_merged : :not_closed_or_merged )

    @sort       = params[:sort] == 'updated' ? :updated : :created
    @direction  = params[:direction] == 'asc' ? :asc : :desc
    @issues = @issues.order("issues.#{@sort}_at #{@direction}")
                     .includes(:assignee, :user, :pull_request).uniq
                     .paginate :per_page => 20, :page => params[:page]
    render 'issues_index', :layout => request.xhr? ? 'with_sidebar' : 'application'
  end

  def pull_requests
    issues
  end

  protected

  def find_user_by_key
    key = SshKey.find(params[:key_id])
    @user = key.user
  end
end
