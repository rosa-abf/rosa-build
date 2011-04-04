class Git::TreesController < Git::BaseController

  def show
    @treeish = params[:treeish] ? params[:treeish] : "master"
    @path = params[:path]

    @tree = @git_repository.tree(@treeish)

    @commit = @git_repository.commits(@treeish, 1).first
#    @commit = @git_repository.commit(@treeish) unless @commit

    @tree = @tree / @path if @path

    render :template => "git/repositories/show"
  end
end