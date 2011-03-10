class Git::RepositoriesController < Git::BaseController

  def show
    @commit = @repository.master
    @tree = @commit.tree
  end

  def commits
    branch_name = (params[:branch] ? params[:branch] : "master")
    @commits = @repository.commits(branch_name)
  end

end