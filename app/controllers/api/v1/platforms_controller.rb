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

  def create
    platform_params = params[:platform] || {}
    owner = User.where(:id => platform_params[:owner_id]).first
    @platform.owner = owner || get_owner
    if @platform.save
      render_json_response @platform, 'Platform has been created successfully'
    else
      render_validation_error @platform, 'Platform has not been created'
    end
  end

  def update
    platform_params = params[:platform] || {}
    owner = User.where(:id => platform_params[:owner_id]).first
    platform_params[:owner] = owner if owner
    if @platform.update_attributes(platform_params)
      render_json_response @platform, 'Platform has been updated successfully'
    else
      render_validation_error @platform, 'Platform has not been updated'
    end
  end

  def members
    @members = @platform.members.order('name').paginate(paginate_params)
  end

  def add_member
    if member.present? && @platform.add_member(member)
      render_json_response @platform, "#{member.class.to_s} '#{member.id}' has been added to platform successfully"
    else
      render_validation_error @platform, 'Member has not been added to platform'
    end
  end

  def remove_member
    if member.present? && @platform.remove_member(member)
      render_json_response @platform, "#{member.class.to_s} '#{member.id}' has been removed from platform successfully"
    else
      render_validation_error @platform, 'Member has not been removed from platform'
    end
  end

  def clone
    platform_params = params[:platform] || {}
    platform_params[:owner] = current_user
    @cloned = @platform.full_clone(platform_params)
    if @cloned.persisted?
      render_json_response @platform, 'Platform has been cloned successfully'
    else
      render_validation_error @platform, 'Platform has not been cloned'
    end
  end

  def clear
    @platform.clear
    render_json_response @platform, 'Platform has been cleared successfully'
  end

  def destroy
    @platform.destroy # later with resque
    render_json_response @platform, 'Platform has been destroyed successfully'
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
