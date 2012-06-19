# -*- encoding : utf-8 -*-
class Projects::BuildListsController < Projects::BaseController
  CALLBACK_ACTIONS = [:publish_build, :status_build, :pre_build, :post_build, :circle_build, :new_bbdt]
  NESTED_ACTIONS = [:search, :index, :new, :create]

  before_filter :authenticate_user!, :except => CALLBACK_ACTIONS
  before_filter :authenticate_build_service!, :only => CALLBACK_ACTIONS
  skip_before_filter :authenticate_user!, :only => [:show, :index, :search] if APP_CONFIG['anonymous_access']

  before_filter :find_build_list, :only => [:show, :publish, :cancel, :update]
  before_filter :find_build_list_by_bs, :only => [:publish_build, :status_build, :pre_build, :post_build, :circle_build]

  load_and_authorize_resource :project, :only => NESTED_ACTIONS
  load_and_authorize_resource :build_list, :through => :project, :only => NESTED_ACTIONS, :shallow => true
  load_and_authorize_resource :except => CALLBACK_ACTIONS.concat(NESTED_ACTIONS)

  def search
    new_params = {:filter => {}}
    params[:filter].each do |k,v|
      new_params[:filter][k] = v unless v.empty?
    end
    redirect_to @project ? project_build_lists_path(@project, new_params) : build_lists_path(new_params)
  end

  def index
    @action_url = @project ? search_project_build_lists_path(@project) : search_build_lists_path
    @filter = BuildList::Filter.new(@project, current_user, params[:filter] || {})
    @build_lists = @filter.find.recent.paginate :page => params[:page]

    @build_server_status = begin
      BuildServer.get_status
    rescue Exception # Timeout::Error
      {}
    end
  end

  def new
    # @build_list = BuildList.new # @build_list already created by CanCan
  end

  def create
    notices, errors = [], []
    @platform = Platform.find params[:build_list][:save_to_platform_id]
    params[:build_list][:auto_publish] = false if @platform.released
    Arch.where(:id => params[:arches]).each do |arch|
      Platform.main.where(:id => params[:build_for_platforms]).each do |build_for_platform|
        @build_list = @project.build_lists.build(params[:build_list])
        @build_list.commit_hash = @project.git_repository.commits(@build_list.project_version.match(/^latest_(.+)/).to_a.last || @build_list.project_version).first.id if @build_list.project_version
        @build_list.build_for_platform = build_for_platform; @build_list.arch = arch; @build_list.user = current_user
        @build_list.include_repos = @build_list.include_repos.select {|ir| @build_list.build_for_platform.repository_ids.include? ir.to_i}
        @build_list.priority = current_user.build_priority # User builds more priority than mass rebuild with zero priority
        flash_options = {:project_version => @build_list.project_version, :arch => arch.name, :build_for_platform => build_for_platform.name}
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
      redirect_to project_build_lists_path(@project)
    end
  end

  def show
    @item_groups = @build_list.items.group_by_level
    @advisories = Advisory.all
  end

  def update
    if params[:publish].present? and can?(:publish, @build_list)
      publish
    elsif params[:reject_publish].present? and can?(:reject_publish, @build_list)
      reject_publish
    else
      # King Arthur, we are under attack!
      redirect_to :forbidden and return
    end
  end

  def cancel
    if @build_list.cancel
      redirect_to :back, :notice => t('layout.build_lists.cancel_success')
    else
      redirect_to :back, :notice => t('layout.build_lists.cancel_fail')
    end
  end

  def publish_build
    if params[:status].to_i == 0 # ok
      @build_list.status = BuildList::BUILD_PUBLISHED
      @build_list.package_version = "#{params[:version]}-#{params[:release]}"
      system("cd #{@build_list.project.git_repository.path} && git tag #{@build_list.package_version} #{@build_list.commit_hash}") # TODO REDO through grit
    else
      @build_list.status = BuildList::FAILED_PUBLISH
    end
    @build_list.save

    render :nothing => true, :status => 200
  end

  def status_build
    @item = @build_list.items.find_by_name!(params[:package_name])
    @item.status = params[:status]
    @item.save

    @build_list.container_path = params[:container_path]
    @build_list.save

    @build_list.set_packages(ActiveSupport::JSON.decode(params[:pkg_info]), params[:package_name]) if params[:status].to_i == BuildServer::SUCCESS and params[:pkg_info].present?

    render :nothing => true, :status => 200
  end

  def pre_build
    @build_list.status = BuildServer::BUILD_STARTED
    @build_list.save

    render :nothing => true, :status => 200
  end

  def post_build
    @build_list.status = params[:status]
    @build_list.container_path = params[:container_path]
    @build_list.save

    render :nothing => true, :status => 200

    @build_list.publish if @build_list.auto_publish # && @build_list.can_publish? # later with resque
  end

  def circle_build
    @build_list.is_circle = true
    @build_list.container_path = params[:container_path]
    @build_list.save

    render :nothing => true, :status => 200
  end

  def new_bbdt
    @build_list = BuildList.find_by_id!(params[:web_id])
    @build_list.name = params[:name]
    @build_list.additional_repos = ActiveSupport::JSON.decode(params[:additional_repos])
    @build_list.set_items(ActiveSupport::JSON.decode(params[:items]))
    @build_list.is_circle = (params[:is_circular].to_i != 0)
    @build_list.bs_id = params[:id]
    @build_list.save

    render :nothing => true, :status => 200
  end

  protected

  def find_build_list
    @build_list = BuildList.find(params[:id])
  end

  def find_build_list_by_bs
    @build_list = BuildList.find_by_bs_id!(params[:id])
  end

  def authenticate_build_service!
    if request.remote_ip != APP_CONFIG['build_server_ip']
      render :nothing => true, :status => 403
    end
  end

  def publish
    @build_list.update_type = params[:build_list][:update_type] if params[:build_list][:update_type].present?

    if params[:attach_advisory].present? and params[:attach_advisory] != 'no' and !@build_list.advisory
      if params[:attach_advisory] == 'new'
        # create new advisory
        unless @build_list.build_advisory(params[:build_list][:advisory]) do |a|
              a.update_type = @build_list.update_type
              a.project     = @build_list.project
              a.platforms  << @build_list.save_to_platform unless a.platforms.include? @build_list.save_to_platform
            end.save
          redirect_to :back, :notice => t('layout.build_lists.publish_fail') and return
        end
      else
        # attach existing advisory
        a = Advisory.where(:advisory_id => params[:attach_advisory]).limit(1).first
        if a.update_type != @build_list.update_type
          redirect_to :back, :notice => t('layout.build_lists.publish_fail') and return
        end
        a.platforms  << @build_list.save_to_platform unless a.platforms.include? @build_list.save_to_platform
        @build_list.advisory = a
        unless a.save
          redirect_to :back, :notice => t('layout.build_lists.publish_fail') and return
        end
      end
    end
    if @build_list.save and @build_list.now_publish
      redirect_to :back, :notice => t('layout.build_lists.publish_success')
    else
      redirect_to :back, :notice => t('layout.build_lists.publish_fail')
    end
  end

  def reject_publish
    if @build_list.reject_publish
      redirect_to :back, :notice => t('layout.build_lists.reject_publish_success')
    else
      redirect_to :back, :notice => t('layout.build_lists.reject_publish_fail')
    end
  end

end
