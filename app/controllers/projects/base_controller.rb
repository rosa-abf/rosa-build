# -*- encoding : utf-8 -*-
class Projects::BaseController < ApplicationController
  prepend_before_filter :find_project
  before_filter :init_statistics

  protected

  def find_project
    @project = Project.find_by_owner_and_name!(params[:owner_name], params[:project_name]) if params[:owner_name] && params[:project_name]
  end

  def init_statistics
    @opened_issues_count        = @project.has_issues ? @project.issues.without_pull_requests.opened.count : 0
    @opened_pull_requests_count = @project.issues.joins(:pull_request).opened.count
  end
end
