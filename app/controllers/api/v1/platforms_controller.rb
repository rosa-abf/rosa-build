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
      render :json => {
        :platform => {
          :id => @platform.id,
          :message => 'Platform has been updated successfully'
        }
      }.to_json
    else
      render :json => validation_failed(@platform), :status => 422
    end
  end

  def members
    @members = @platform.members.order('name').paginate(paginate_params)
  end

  def add_member
    if member.present? && @platform.add_member(member)
      render :json => {
        :platform => {
          :id => @platform.id,
          :message => "#{member.class.to_s} '#{member.id}' has been added to platform successfully"
        }
      }.to_json
    else
      render :json => validation_failed(@platform), :status => 422
    end
  end

  def remove_member
    if member.present? && @platform.remove_member(member)
      render :json => {
        :platform => {
          :id => @platform.id,
          :message => "#{member.class.to_s} '#{member.id}' has been removed from platform successfully"
        }
      }.to_json
    else
      render :json => validation_failed(@platform), :status => 422
    end
  end

  private

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
