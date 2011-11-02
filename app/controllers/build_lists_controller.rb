class BuildListsController < ApplicationController
	before_filter :authenticate_user!, :except => [:status_build, :pre_build, :post_build, :circle_build, :new_bbdt]
	before_filter :authenticate_build_service!, :only => [:status_build, :pre_build, :post_build, :circle_build, :new_bbdt]
	before_filter :find_project, :only => [:index, :filter, :show, :publish]
	before_filter :find_arches, :only => [:index, :filter, :all]
	before_filter :find_project_versions, :only => [:index, :filter]
	before_filter :find_build_list_by_bs, :only => [:status_build, :pre_build, :post_build]
  before_filter :check_global_access, :except => [:status_build, :post_build, :pre_build, :circle_build, :new_bbdt, :show, :publish, :cancel]

	def all
    if params[:filter]
      @filter = BuildList::Filter.new(nil, params[:filter])
      @build_lists = @filter.find.paginate :page => params[:page]
    else
      @filter = BuildList::Filter.new(nil)
      @build_lists = BuildList.recent.paginate :page => params[:page]
    end
		@action_url = all_build_lists_path
		
    @build_server_status = BuildServer.get_status
	  #@build_server_status = {:client_count => '1', :count_new_task => '2', :count_build_task => 3}
	  
    render :action => 'index'
	end
	
	def cancel
	 build_list = BuildList.find(params[:id])
   can_perform? build_list.project if build_list
   if build_list.delete_build_list
     redirect_to :back, :notice => t('layout.build_lists.cancel_successed')
   else
     redirect_to :back, :notice => t('layout.build_lists.cancel_failed')
   end
	end

	def index
		@build_lists = @project.build_lists.recent.paginate :page => params[:page]
		@filter = BuildList::Filter.new(@project)
		@action_url = project_build_lists_path(@project)
	end

	def filter
		@filter = BuildList::Filter.new(@project, params[:filter])
		@build_lists = @filter.find.paginate :page => params[:page]
		@action_url = project_build_lists_path(@project)

		render :action => "index"
	end

	def show
    can_perform? @project
		@build_list = @project.build_lists.find(params[:id])
		@item_groups = @build_list.items.group_by_level
	end
	
	def publish
    can_perform? @project if @project
		@build_list = @project.build_lists.find(params[:id])
		@build_list.publish
		
		redirect_to project_build_lists_path(@project)
	end

	def status_build
		@item = @build_list.items.find_by_name!(params[:package_name])
		@item.status = params[:status]
		@item.save
		
		@build_list.container_path = params[:container_path]
		@build_list.notified_at = Time.now

		@build_list.save

		render :nothing => true, :status => 200
	end

	def pre_build
		@build_list.status = BuildList::BUILD_STARTED
		@build_list.notified_at = Time.now

		@build_list.save

		render :nothing => true, :status => 200
	end

	def post_build
		@build_list.status = params[:status]
		@build_list.container_path = params[:container_path]
		@build_list.notified_at = Time.now

		@build_list.save

		render :nothing => true, :status => 200
	end

	def circle_build
		@build_list.is_circle = true
		@build_list.container_path = params[:container_path]
		@build_list.notified_at = Time.now

		@build_list.save

		render :nothing => true, :status => 200
	end

	def new_bbdt
		@build_list = BuildList.find_by_id!(params[:web_id])
		@build_list.name = params[:name]
		@build_list.additional_repos = ActiveSupport::JSON.decode(params[:additional_repos])
		@build_list.set_items(ActiveSupport::JSON.decode(params[:items]))
		@build_list.notified_at = Time.now
		@build_list.is_circle = (params[:is_circular] != "0")
		@build_list.bs_id = params[:id]
		params[:arch]
		@build_list.save

		render :nothing => true, :status => 200
	end

	protected
	
		def find_project
			@project = Project.find params[:project_id]
		end

		def find_arches
			@arches = Arch.recent
		end

		def find_project_versions
			@git_repository = @project.git_repository
			@project_versions = @project.project_versions
		end

		def find_build_list_by_bs
			@build_list = BuildList.find_by_bs_id!(params[:id])
		end

end
