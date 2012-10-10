# -*- encoding : utf-8 -*-
class Api::V1::PlatformsController < Api::V1::BaseController

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show, :platforms_for_build, :members] if APP_CONFIG['anonymous_access']

  load_and_authorize_resource

  def index
    @platforms = @platforms.accessible_by(current_ability, :related).
      by_type(params[:type]).paginate(paginate_params)
  end

  def show
  end

  def platforms_for_build
  	@platforms = Platform.main.opened.paginate(paginate_params)
  	render :index
  end

  def update
    p = params[:platform] || {}
    owner = User.where(:id => p[:owner_id]).first
    platform_params = {}
    platform_params[:owner]       = owner if owner
    platform_params[:released]    = p[:released] if p[:released]
    platform_params[:description] = p[:description] if p[:description]
    if @platform.update_attributes(p)
      render :json => json_response('Platform has been updated successfully')
    else
      render :json => json_response('Platform has not been updated', true), :status => 422
    end
  end

  def members
    @members = @platform.members.order('name').paginate(paginate_params)
  end

  def add_member
    if member.present? && @platform.add_member(member)
      render :json => json_response("#{member.class.to_s} '#{member.id}' has been added to platform successfully")
    else
      render :json => json_response('Member has not been added to platform', true), :status => 422
    end
  end

  def remove_member
    if member.present? && @platform.remove_member(member)
      render :json => json_response("#{member.class.to_s} '#{member.id}' has been removed from platform successfully")
    else
      render :json => json_response('Member has not been removed from platform'), :status => 422
    end
  end

  def clone
    p = params[:platform] || {}
    platform_params = {}
    platform_params[:description] = p[:description] if p[:description]
    platform_params[:name]        = p[:name] if p[:name]
    platform_params[:owner]       = current_user
    @cloned = @platform.full_clone(platform_params)
    if @cloned.persisted?
      render :json => json_response('Platform has been cloned successfully')
    else
      render :json => json_response('Platform has not been cloned', true), :status => 422
    end
  end

  def clear
    @platform.clear
    render :json => json_response('Platform has been cleared successfully')
  end

  def destroy
    @platform.destroy # later with resque
    render :json => json_response('Platform has been destroyed successfully')
  end

  private

  def json_response(message, nullify_id = false)
    id = nullify_id ? nil : @platform.id
    { :platform => {:id => id, :message => message} }.to_json
  end

  def member
    return @member if @member
    if params[:type] == 'User'
      member = User
    elsif params[:type] == 'Group'
      member = Group
    end
    @member = member.where(:id => params[:member_id]).first if member
    @member ||= ''
  end

end
