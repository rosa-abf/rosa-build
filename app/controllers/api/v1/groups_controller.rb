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
    @group = Group.new params[:group]
    @group.owner = current_user
    create_subject @group
  end

end