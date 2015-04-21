class Projects::BaseController < ApplicationController
  prepend_before_action :authenticate_user_and_find_project
  before_action :init_statistics

  protected

  def find_collaborators
    search = "%#{params[:search_user]}%"
    @users = @project.collaborators.where("users.uname ILIKE ?", search)
    @users |= @project.owner.members.where("users.uname ILIKE ?", search) if @project.owner.is_a?(Group)
    @users = @users.sort_by(&:uname).first(10)
  end

  def authenticate_user_and_find_project
    authenticate_user
    return if params[:name_with_owner].blank?
    authorize @project = Project.find_by_owner_and_name!(params[:name_with_owner]), :show?
  end

  def init_statistics
    if @project
      @opened_issues_count        = @project.issues.without_pull_requests.not_closed_or_merged.count
      @opened_pull_requests_count = @project.issues.joins(:pull_request).not_closed_or_merged.count
    end
  end
end
