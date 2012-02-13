# -*- encoding : utf-8 -*-
class Git::TreesController < Git::BaseController

  def show
    @path = params[:path]
    @path.force_encoding(Encoding::ASCII_8BIT) if @path

    @tree = @git_repository.tree(@treeish)

#    @commit = @git_repository.commits(@treeish, 1).first
#   Raises Grit::Git::GitTimeout
    @commit = @git_repository.log(@treeish, @path).first

    @tree = @tree / @path if @path

    render :template => "git/repositories/show"
  end
end
