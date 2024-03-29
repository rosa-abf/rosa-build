class Api::V1::GroupsController < Api::V1::BaseController

  before_action :authenticate_user!
  # skip_before_action :authenticate_user!, only: [:show, :projects] if APP_CONFIG['anonymous_access']
  before_action :load_group, except: %i(index create)

  def index
    authorize :group
    @groups = current_user.groups.paginate(paginate_params)
  end

  def show
    authorize @group
  end

  def members
    authorize @group
    @members = @group.members.where('actor_id != ?', @group.owner_id)
                     .order('name').paginate(paginate_params)
  end

  def projects
    authorize @group
    render plain: @group.projects.pluck(:owner_uname, :name).map { |p| "#{p[0]}/#{p[1]}" }.join("\n")
  end

  def update
    update_subject @group
  end

  def destroy
    destroy_subject @group
  end

  def create
    @group = current_user.own_groups.new
    @group.assign_attributes(group_params)
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

  private

  def group_params
    subject_params(Group, @group)
  end

  # Private: before_action hook which loads Group.
  def load_group
    @group = Group.find params[:id]
  end

end
