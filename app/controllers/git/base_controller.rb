class Git::BaseController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_platform
  before_filter :find_repository
  before_filter :find_project
  before_filter :find_git_repository
  before_filter :find_tags
  before_filter :find_branches
  before_filter :set_treeish
  before_filter :set_current_tag
  before_filter :set_current_branch

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

    def find_tags
      @tags = @git_repository.tags
    end

    def find_branches
      @branches = @git_repository.branches
    end

    def set_treeish
      @treeish = params[:treeish] ? params[:treeish] : "master"
    end

    def set_current_tag
      @current_tag = @tags.select{|t| t.name == @treeish }.first
    end

    def set_current_branch
      @current_branch = @branches.select{|b| b.name == @treeish }.first
    end
end