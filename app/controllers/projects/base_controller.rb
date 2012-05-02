# -*- encoding : utf-8 -*-
class Projects::BaseController < ApplicationController
  prepend_before_filter :find_project

  protected

  def find_project
    @project = Project.find_by_owner_and_name!(params[:owner_name], params[:project_name]) if params[:owner_name] && params[:project_name]
  end
end
