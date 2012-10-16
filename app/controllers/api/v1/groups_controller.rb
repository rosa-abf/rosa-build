# -*- encoding : utf-8 -*-
class Api::V1::GroupsController < Api::V1::BaseController
  
  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, :only => [:show] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource

  def index
    # accessible_by(current_ability)
    @groups = current_user.groups.paginate(paginate_params)
  end

  def show
  end

  def members
    @members = @group.members.
      where('actor_id != ?', @group.owner_id).
      order('name').paginate(paginate_params)
  end

  def update
    update_subject @group
  end

  def destroy
    destroy_subject @group
  end

  def create
    @group = current_user.own_groups.new params[:group]
    create_subject @group
  end

  def add_member
    params[:type] = 'User'
    add_member_to_subject @group, (params[:role] || 'admin')
  end

  def remove_member
    params[:type] = 'User'
    remove_member_from_subject @group
  end

  def update_member
    member_id, role = params[:member_id], params[:role]
    if member_id.present? && role.present? && @group.owner_id != member_id.to_i &&
      @group.actors.where(:actor_id => member_id, :actor_type => 'User').
        update_all(:role => role)
      render_json_response @group, "Role for user #{member_id} has been updated in group successfully"
    else
      render_validation_error @group, 'Role for user has not been updated in group'
    end
  end

end