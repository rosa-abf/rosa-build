class Git::TreesController < Git::BaseController

  def show
    @treeish = params[:treeish] ? params[:treeish] : "master"
    @path = params[:path]

    @tree = @repository.tree(@treeish)

    # ???
#    @tree = @tree / @path if @path

    render :template => "git/repositories/show"
  end
end