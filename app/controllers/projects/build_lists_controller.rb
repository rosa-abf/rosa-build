# -*- encoding : utf-8 -*-
class Projects::BuildListsController < Projects::BaseController
  CALLBACK_ACTIONS = [:publish_build, :status_build, :pre_build, :post_build, :circle_build, :new_bbdt]
  NESTED_ACTIONS = [:search, :index, :new, :create]

  before_filter :authenticate_user!, :except => CALLBACK_ACTIONS
  before_filter :authenticate_build_service!, :only => CALLBACK_ACTIONS
  skip_before_filter :authenticate_user!, :only => [:show, :index, :search, :log] if APP_CONFIG['anonymous_access']

  before_filter :find_build_list, :only => [:show, :publish, :cancel, :update, :log]
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

    page = params[:page].to_i == 0 ? nil : params[:page]
    @bls = @filter.find.recent.paginate :page => page
    @build_lists = BuildList.where(:id => @bls.pluck("#{BuildList.table_name}.id")).recent
    @build_lists = @build_lists.includes [:save_to_platform, :save_to_repository, :arch, :user, :project => [:owner]]

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

    @repository = Repository.find params[:build_list][:save_to_repository_id]
    @platform = @repository.platform

    params[:build_list][:save_to_platform_id] = @platform.id
    params[:build_list][:auto_publish] = false unless @repository.publish_without_qa?


    build_for_platforms = Repository.select(:platform_id).
      where(:id => params[:build_list][:include_repos]).group(:platform_id).map(&:platform_id)

    Arch.where(:id => params[:arches]).each do |arch|
      Platform.main.where(:id => build_for_platforms).each do |build_for_platform|
        @build_list = @project.build_lists.build(params[:build_list])
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
      notice = @build_list.new_core? ?
       t('layout.build_lists.will_be_canceled') :
       t('layout.build_lists.cancel_success')
    else
      notice = t('layout.build_lists.cancel_fail')
    end
    redirect_to :back, :notice => notice
  end

  def log
    render :json => {
      :log => @build_list.log(params[:load_lines]),
      :building => @build_list.build_started?
    }
  end

  def publish_build
    if params[:status].to_i == 0 # ok
      @build_list.published
    else
      @build_list.fail_publish
    end
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
    @build_list.start_build

    render :nothing => true, :status => 200
  end

  def post_build
    params[:status].to_i == BuildServer::SUCCESS ? @build_list.build_success : @build_list.build_error
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

      unless @build_list.update_type.in? BuildList::RELEASE_UPDATE_TYPES
        redirect_to :back, :notice => t('lyout.build_lists.publish_fail') and return
      end

      if params[:attach_advisory] == 'new'
        # create new advisory
        unless @build_list.associate_and_create_advisory(params[:build_list][:advisory])
          redirect_to :back, :notice => t('layout.build_lists.publish_fail') and return
        end
      else
        # attach existing advisory
        a = Advisory.where(:advisory_id => params[:attach_advisory]).first
        unless (a && a.attach_build_list(@build_list))
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
