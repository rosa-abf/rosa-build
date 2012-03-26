# -*- encoding : utf-8 -*-
class Git::BaseController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :project

  before_filter :find_git_repository
  before_filter :find_tags
  before_filter :find_branches
  before_filter :set_treeish
  before_filter :set_current_tag
  before_filter :set_current_branch

  protected
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
      @treeish = params[:treeish].presence || @project.default_branch
    end

    def set_current_tag
      @current_tag = @tags.select{|t| t.name == @treeish }.first
    end

    def set_current_branch
      @current_branch = @branches.select{|b| b.name == @treeish }.first
    end
end
