class Git::RepositoriesController < Git::BaseController

  def show
    @commit = @git_repository.master
    @tree = @commit.tree
  end

end