class Git::BaseController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_project
  before_filter :find_repository

  protected
    def find_project
      @project = Project.find_by_title!(params[:project_name])
    end

    def find_repository
      @repository = @project.git_repository
    end
end