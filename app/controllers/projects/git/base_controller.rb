# -*- encoding : utf-8 -*-
class Projects::Git::BaseController < Projects::BaseController
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show, :index, :blame, :raw, :archive] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource :project

  before_filter :set_treeish_and_path
  before_filter :set_branch_and_tree

  protected

  def set_treeish_and_path
    @treeish = params[:treeish].presence
    unless @treeish
      commit = @project.repo.commits(@project.default_branch, 1).first
      @treeish = commit ? commit.id : @project.default_branch
    end
    @path = params[:path]
  end

  def set_branch_and_tree
    @branch = @project.repo.branches.detect{|b| b.name == @treeish}
    @tree = @project.repo.tree(@treeish)
    if @branch
      commit = @project.repo.commits(@treeish, 1).first
      @treeish = commit.id if commit 
    end
    # raise Grit::NoSuchPathError if @tree.blobs.blank?
  end
end
