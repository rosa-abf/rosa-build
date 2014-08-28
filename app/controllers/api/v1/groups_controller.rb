class Api::V1::GroupsController < Api::V1::BaseController

  before_filter :authenticate_user!
  skip_before_filter :authenticate_user!, only: [:show] if APP_CONFIG['anonymous_access']
  load_and_authorize_resource

  def index
    # accessible_by(current_ability)
    @groups = current_user.groups.paginate(paginate_params)
    respond_to do |format|
      format.json
    end
  end

  def show
    respond_to do |format|
      format.json
    end
  end

  def members
    @members = @group.members.where('actor_id != ?', @group.owner_id)
                     .order('name').paginate(paginate_params)
    respond_to do |format|
      format.json
    end
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
    params[:type] = 'User'
    update_member_in_subject @group, :actors
  end

end
