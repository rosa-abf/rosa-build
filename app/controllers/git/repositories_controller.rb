# -*- encoding : utf-8 -*-
class Git::RepositoriesController < Git::BaseController

  def show
    @commit = @git_repository.master
    @tree = @commit ? @commit.tree : nil

    render :template => "git/repositories/empty" unless @tree
  end

end
