class Git::RepositoriesController < Git::BaseController

  def show
    @commit = @repository.master
    @tree = @commit.tree
  end

  protected
    def find_platform
      @platform = Platform.find params[:platform_id]
    end

    def find_project
      @project = Project.find params[:project_id]
    end

end