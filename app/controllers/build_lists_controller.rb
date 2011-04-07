class BuildListsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_platform, :only => [:index, :filter]
  before_filter :find_repository, :only => [:index, :filter]
  before_filter :find_project, :only => [:index, :filter]
  before_filter :find_arches, :only => [:index, :filter]
  before_filter :find_branches, :only => [:index, :filter]

  def index
    @build_lists = @project.build_lists.recent.paginate :page => params[:page]
    @filter = BuildList::Filter.new(@project)
  end

  def filter
    @filter = BuildList::Filter.new(@project, params[:filter])
    @build_lists = @filter.find.paginate :page => params[:page]

    render :action => "index"
  end

  def status_build
    @build_list = BuildList.find_by_bs_id!(params[:id])

    @build_list.status = params[:status]
    @build_list.container_path = params[:container_path]
    @build_list.notified_at = Time.now

    @build_list.save

    render :nothing => true, :status => 200
  end

  protected
    def find_platform
      @platform = Platform.find params[:platform_id]
    end

    def find_repository
      @repository = @platform.repositories.find(params[:repository_id])
    end

    def find_project
      @project = @repository.projects.find params[:project_id]
    end

    def find_arches
      @arches = Arch.recent
    end

    def find_branches
      @git_repository = @project.git_repository
      @branches = @git_repository.branches
    end

end