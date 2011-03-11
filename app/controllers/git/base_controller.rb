class Git::BaseController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_platform
  before_filter :find_repository
  before_filter :find_project
  before_filter :find_git_repository

  protected
    def find_platform
      @platform = Platform.find(params[:platform_id])
    end

    def find_repository
      @repository = @platform.repositories.find(params[:repository_id])
    end

    def find_project
      @project = @repository.projects.find(params[:project_id])
    end

    def find_git_repository
      @git_repository = @project.git_repository
    end
end