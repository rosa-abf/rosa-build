class BuildListsController < ApplicationController
  CALLBACK_ACTIONS = [:status_build, :pre_build, :post_build, :circle_build, :new_bbdt]

  before_filter :authenticate_user!, :except => CALLBACK_ACTIONS
  before_filter :authenticate_build_service!, :only => CALLBACK_ACTIONS
  before_filter :find_project, :only => [:filter, :show, :publish, :new, :create]
  before_filter :find_arches, :only => [:index]
  before_filter :find_build_list_by_bs, :only => [:status_build, :pre_build, :post_build]

  load_and_authorize_resource :project, :only => :index
  load_and_authorize_resource :through => :project, :only => :index, :shallow => true
  load_and_authorize_resource :except => CALLBACK_ACTIONS.concat([:index])

	def index
    filter_params = params[:filter] || {}
    if params[:project_id]
      find_project
      find_project_versions
      @action_url = project_build_lists_path(@project)
    else
      @project = nil
      @action_url = build_lists_path
    end

    @filter = BuildList::Filter.new(@project, filter_params)
		@build_lists = @filter.find.accessible_by(current_ability).recent.paginate :page => params[:page]

    @build_server_status = begin
      BuildServer.get_status
    rescue Exception # Timeout::Error
      {}
    end
	end

	def show
		@build_list = @project.build_lists.find(params[:id])
		@item_groups = @build_list.items.group_by_level
	end
	
	def new
	  @build_list = BuildList.new
  end

  def create
    notices, errors = [], []
    Arch.where(:id => params[:archs]).each do |arch|
      Platform.main.where(:id => params[:bpls]).each do |bpl|
        @build_list = @project.build_lists.build(params[:build_list])
        @build_list.bpl = bpl; @build_list.arch = arch; @build_list.user = current_user
        flash_options = {:project_version => @build_list.project_version, :arch => arch.name, :bpl => bpl.name, :pl => @build_list.pl}
        if @build_list.save
          notices << t("flash.build_list.saved", flash_options)
        else
          errors << t("flash.build_list.save_error", flash_options)
        end
      end
    end
    errors << t("flash.build_list.no_arch_or_platform_selected") if errors.blank? and notices.blank?
    if errors.present?
      @build_list ||= BuildList.new
      flash[:error] = errors.join('<br>').html_safe
      render :action => :new
    else
      flash[:notice] = notices.join('<br>').html_safe
      redirect_to @project
    end
  end
  
	def publish
		@build_list = @project.build_lists.find(params[:id])
		@build_list.publish
		
		redirect_to project_build_lists_path(@project)
	end

	def cancel
		build_list = BuildList.find(params[:id])
		if build_list.cancel_build_list
			redirect_to :back, :notice => t('layout.build_lists.cancel_successed')
		else
			redirect_to :back, :notice => t('layout.build_lists.cancel_failed')
		end
	end

	def status_build
		@item = @build_list.items.find_by_name!(params[:package_name])
		@item.status = params[:status]
		@item.save
		
		@build_list.container_path = params[:container_path]
		@build_list.notified_at = Time.current

		@build_list.save

		render :nothing => true, :status => 200
	end

	def pre_build
		@build_list.status = BuildServer::BUILD_STARTED
		@build_list.notified_at = Time.current

		@build_list.save

		render :nothing => true, :status => 200
	end

	def post_build
		@build_list.status = params[:status]
		@build_list.container_path = params[:container_path]
		@build_list.notified_at = Time.current

		@build_list.save

		render :nothing => true, :status => 200
	end

	def circle_build
		@build_list.is_circle = true
		@build_list.container_path = params[:container_path]
		@build_list.notified_at = Time.current

		@build_list.save

		render :nothing => true, :status => 200
	end

	def new_bbdt
		@build_list = BuildList.find_by_id!(params[:web_id])
		@build_list.name = params[:name]
		@build_list.additional_repos = ActiveSupport::JSON.decode(params[:additional_repos])
		@build_list.set_items(ActiveSupport::JSON.decode(params[:items]))
		@build_list.notified_at = Time.current
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
			@project_versions = @project.versions
		end

		def find_build_list_by_bs
			@build_list = BuildList.find_by_bs_id!(params[:id])
		end

    def authenticate_build_service!
      if request.remote_ip != APP_CONFIG['build_server_ip']
        render :nothing => true, :status => 403
      end
    end
end
