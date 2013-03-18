class Projects::BaseController < ApplicationController
  prepend_before_filter :find_project
  before_filter :init_statistics

  protected

  def find_project
    @project = Project.find_by_owner_and_name!(params[:owner_name], params[:project_name]) if params[:owner_name] && params[:project_name]
  end

  def init_statistics
    if @project
      @opened_issues_count        = @project.issues.without_pull_requests.not_closed_or_merged.count
      @opened_pull_requests_count = @project.issues.joins(:pull_request).not_closed_or_merged.count
    end
  end
end
