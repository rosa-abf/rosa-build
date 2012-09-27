# -*- encoding : utf-8 -*-
class Api::V1::BuildListsController < Api::V1::BaseController
  
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show, :index] if APP_CONFIG['anonymous_access']
  
  load_and_authorize_resource :project, :only => :index
  load_and_authorize_resource :build_list, :only => [:show, :create, :cancel, :publish, :reject_publish]
  
  def index
    filter = BuildList::Filter.new(nil, current_user, params[:filter] || {})
    @build_lists = filter.find.scoped(:include => [:save_to_platform, :project, :user, :arch])
    @build_lists = @build_lists.recent.paginate :page => params[:page], :per_page => params[:per_page]
  end

  def create
    project = Project.find(params[:build_list][:project_id])
    save_to_repository = Repository.find params[:build_list][:save_to_repository_id] #FIXME
    params[:build_list][:save_to_platform_id] = save_to_repository.platform_id
    params[:build_list][:auto_publish] = false unless save_to_repository.publish_without_qa?

    @build_list = project.build_lists.build(params[:build_list])
    @build_list.project_version = @build_list.commit_hash

    @build_list.user = current_user
    @build_list.priority = current_user.build_priority # User builds more priority than mass rebuild with zero priority

    if @build_list.save
      render :action => 'show'
    else
      render :json => {:message => "Validation Failed", :errors => @build_list.errors.messages}.to_json, :status => 422
    end
  end

  def cancel
    render_json :cancel
  end

  def publish
    render_json :publish
  end

  def reject_publish
    render_json :reject_publish
  end

  private

  def render_json(action_name)
    if @build_list.send(action_name)
      render :json => {:"is_#{action_name}ed" => true, :url => api_v1_build_list_path(@build_list, :format => :json), :message => t("layout.build_lists.#{action_name}_success")}
    else
      render :json => {:"is_#{action_name}ed" => false, :url => api_v1_build_list_path(@build_list, :format => :json), :message => t("layout.build_lists.#{action_name}_fail")}
    end
  end

end
