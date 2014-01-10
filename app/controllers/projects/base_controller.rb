class Projects::BaseController < ApplicationController
  prepend_before_filter :find_project
  before_filter :init_statistics

  protected

  def find_collaborators
    search = "%#{params[:search_user]}%"
    users = User.joins(:groups => :projects).where(:projects => {:id => @project.id}).where("users.uname ILIKE ?", search)
    users2 = @project.collaborators.where("users.uname ILIKE ?", search)
    @users = (users + users2).uniq.sort {|x,y| x.uname <=> y.uname}.first(10)
  end

  def find_project
    @project = Project.find_by_owner_and_name!(params[:owner_name], params[:project_name]) if params[:owner_name].present? && params[:project_name].present?
  end

  def init_statistics
    if @project
      @opened_issues_count        = @project.issues.without_pull_requests.not_closed_or_merged.count
      @opened_pull_requests_count = @project.issues.joins(:pull_request).not_closed_or_merged.count
    end
  end
end
