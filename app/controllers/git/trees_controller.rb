# -*- encoding : utf-8 -*-
class Git::TreesController < Git::BaseController

  def show
    if params[:treeish].present? and @treeish.dup.encode_to_default == @project.default_branch
      redirect_to project_path(@project) and return
    end

    @path = params[:path]

    @tree = @git_repository.tree(@treeish)
    @branch = @project.branch(@treeish)

#    @commit = @git_repository.commits(@treeish, 1).first
#   Raises Grit::Git::GitTimeout
    @commit = @branch.present? ? @branch.commit() : @git_repository.log(@treeish, @path, :max_count => 1).first

    if @path
      @path.force_encoding(Encoding::ASCII_8BIT)
      @tree = @tree / @path
    end

    render :template => "git/repositories/show"
  end
end
