# -*- encoding : utf-8 -*-
class Projects::BuildListsController < Projects::BaseController
  NESTED_ACTIONS = [:search, :index, :new, :create]

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show, :index, :search, :log] if APP_CONFIG['anonymous_access']

  before_filter :find_build_list, :only => [:show, :publish, :cancel, :update, :log, :create_container]

  load_and_authorize_resource :project, :only => NESTED_ACTIONS
  load_and_authorize_resource :build_list, :through => :project, :only => NESTED_ACTIONS, :shallow => true
  load_and_authorize_resource :except => NESTED_ACTIONS

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

    @build_server_status = AbfWorker::StatusInspector.projects_status
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

  def create_container
    if @build_list.publish_container
      redirect_to :back, :notice => t('layout.build_lists.create_container_success')
    else
      redirect_to :back, :notice => t('layout.build_lists.create_container_fail')
    end
  end

  def cancel
    if @build_list.cancel
      redirect_to :back, :notice => t('layout.build_lists.will_be_canceled')
    else
      redirect_to :back, :notice => t('layout.build_lists.cancel_fail')
    end
  end

  def log
    render :json => {
      :log => @build_list.log(params[:load_lines]),
      :building => @build_list.build_started?
    }
  end

  def autocomplete_to_extra
    platforms = Platform.includes(:repositories).search(params[:term]).search_order.limit(5)
    results = []
    platforms.each{ |p| p.repositories.each{ |r| results << {id: r.id, label: "#{p.name}/#{r.name}", value: "#{p.name}/#{r.name}"} } }

    bl = BuildList.where(id: params[:term]).first
    results << {id: "#{bl.id}-build-list", value: bl.id, label: "#{bl.id} (#{bl.project.name} - #{bl.arch.name})"} if bl
    render json: results.to_json
  end

  def add_extra
    if params[:extra_id] =~ /-build-list$/
      id = params[:extra_id].gsub(/-build-list$/, '')
      subject = BuildList.where(id: id, container_status: BuildList::BUILD_PUBLISHED).first
    else
      subject = Repository.find params[:extra_id]
    end
    render partial: 'extra', locals: {subject: subject}
  end

  protected

  def find_build_list
    @build_list = BuildList.find(params[:id])
  end

  def publish
    @build_list.update_type = params[:build_list][:update_type] if params[:build_list][:update_type].present?

    if params[:attach_advisory].present? and params[:attach_advisory] != 'no' and !@build_list.advisory

      unless @build_list.update_type.in? BuildList::RELEASE_UPDATE_TYPES
        redirect_to :back, :notice => t('layout.build_lists.publish_fail') and return
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
