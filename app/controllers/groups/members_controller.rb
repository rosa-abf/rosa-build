class Groups::MembersController < Groups::BaseController
  before_action -> { authorize @group, :manage_members?  }

  def index
    @members = @group.members.order(:uname) - [@group.owner]
  end

  def update
    raise Pundit::NotAuthorizedError if @group.owner_id.to_s == params[:member_id]

    relation   = @group.actors.where(actor_id: params[:member_id], actor_type: 'User').first
    relation ||= @group.actors.build(actor_id: params[:member_id], actor_type: 'User')
    relation.role = params[:role]
    relation.save!

    flash[:notice] = t("flash.members.successfully_changed")
    redirect_to group_members_path(@group)
  end

  def remove
    User.where(id: params[:members]).each do |user|
      @group.remove_member(user)
    end
    redirect_to group_members_path(@group)
  end

  def add
    @user = User.find_by(id: params[:member_id])
    if !@user
      flash[:error] = t("flash.collaborators.wrong_user", uname: params[:user_uname])
    elsif @group.add_member(@user, params[:role])
      flash[:notice] = t("flash.members.successfully_added")
    else
      flash[:error] = t("flash.members.error_in_adding")
    end
    redirect_to group_members_path(@group)
  end
end
