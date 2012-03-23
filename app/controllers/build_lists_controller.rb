# -*- encoding : utf-8 -*-
class BuildListsController < ApplicationController
  CALLBACK_ACTIONS = [:publish_build, :status_build, :pre_build, :post_build, :circle_build, :new_bbdt]
  NESTED_ACTIONS = [:search, :index, :new, :create]

  before_filter :authenticate_user!, :except => CALLBACK_ACTIONS
  before_filter :authenticate_build_service!, :only => CALLBACK_ACTIONS
  before_filter :find_project, :only => NESTED_ACTIONS
  before_filter :find_build_list, :only => [:show, :publish, :cancel]
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
    @build_list = BuildList.new
  end

  def create
    notices, errors = [], []
    Arch.where(:id => params[:arches]).each do |arch|
      Platform.main.where(:id => params[:bpls]).each do |bpl|
        @build_list = @project.build_lists.build(params[:build_list])
        @build_list.commit_hash = @project.git_repository.commits(@build_list.project_version.match(/^latest_(.+)/).to_a.last || @build_list.project_version).first.id if @build_list.project_version
        @build_list.bpl = bpl; @build_list.arch = arch; @build_list.user = current_user
        @build_list.include_repos = @build_list.include_repos.select { |ir| @build_list.bpl.repository_ids.include? ir.to_i }
        @build_list.priority = 100 # User builds more priority than mass rebuild with zero priority
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
      redirect_to project_build_lists_path(@project)
    end
  end

  def show
    @item_groups = @build_list.items.group_by_level
  end

  def publish
    if @build_list.publish
      redirect_to :back, :notice => t('layout.build_lists.publish_success')
    else
      redirect_to :back, :notice => t('layout.build_lists.publish_fail')
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
    @build_list.notified_at = Time.current
    @build_list.save

    render :nothing => true, :status => 200
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

    @build_list.delay.publish if @build_list.auto_publish # && @build_list.can_publish?
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
    @build_list.is_circle = (params[:is_circular].to_i != 0)
    @build_list.bs_id = params[:id]
    @build_list.notified_at = Time.current
    @build_list.save

    render :nothing => true, :status => 200
  end

  protected

  def find_project
    @project = Project.find_by_id params[:project_id]
  end

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
end
