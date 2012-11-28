# -*- encoding : utf-8 -*-
class Api::V1::BuildListsController < Api::V1::BaseController

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show, :index] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource :project, :only => :index
  load_and_authorize_resource :build_list, :only => [:show, :create, :cancel, :publish, :reject_publish]

  def index
    filter = BuildList::Filter.new(nil, current_user, params[:filter] || {})
    @build_lists = filter.find.scoped(:include => [:save_to_platform, :project, :user, :arch])
    @build_lists = @build_lists.recent.paginate(paginate_params)
  end

  def create
    bl_params = params[:build_list] || {}
    project = Project.where(:id => bl_params[:project_id]).first
    save_to_repository = Repository.where(:id => bl_params[:save_to_repository_id]).first

    if project && save_to_repository
      bl_params[:save_to_platform_id] = save_to_repository.platform_id
      bl_params[:auto_publish] = false unless save_to_repository.publish_without_qa?

      @build_list = project.build_lists.build(bl_params)

      @build_list.user = current_user
      @build_list.priority = current_user.build_priority # User builds more priority than mass rebuild with zero priority

      if @build_list.save
        render :action => 'show'
      else
        render :json => {:message => "Validation Failed", :errors => @build_list.errors.messages}.to_json, :status => 422
      end
    else
      render :json => {:message => "Bad Request"}.to_json, :status => 400
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
    res, message = if !@build_list.send "can_#{action_name}?"
                     [false, "Incorrect action for current status"]
                   elsif @build_list.send(action_name)
                     [true, t("layout.build_lists.#{action_name}_success")]
                   else
                     [false, t("layout.build_lists.#{action_name}_fail")]
                   end

   render :json => {:"is_#{action_name}ed" => res, :url => api_v1_build_list_path(@build_list, :format => :json), :message => message}
  end
end
