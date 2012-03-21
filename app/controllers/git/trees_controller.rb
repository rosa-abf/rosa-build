# -*- encoding : utf-8 -*-
class Git::TreesController < Git::BaseController
  def show
    redirect_to project_path(@project) and return if params[:treeish] == @project.default_branch and params[:path].blank?

    @path = params[:path]
    @tree = @git_repository.tree(@treeish)
    @branch = @project.branch(@treeish)

#    @commit = @git_repository.commits(@treeish, 1).first
#   Raises Grit::Git::GitTimeout
    @commit = @branch.present? ? @branch.commit() : @git_repository.log(@treeish, @path, :max_count => 1).first
    render :template => "git/trees/empty" and return unless @commit

    @tree = @tree / @path if @path
    render :template => "git/trees/show"
  end
end
