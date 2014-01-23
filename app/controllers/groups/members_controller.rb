class Groups::MembersController < Groups::BaseController
  is_related_controller!
  belongs_to :group, finder: 'find_by_insensitive_uname!', optional: true

  before_filter lambda { authorize! :manage_members, @group }

  def index
  end

  def update
    params['user'].keys.each do |user_id|
      role = params['user'][user_id]
      if relation = parent.actors.where(actor_id: user_id, actor_type: 'User') #find_by_actor_id_and_actor_type(user_id, 'User')
        relation.update_all(role: role) if parent.owner.id.to_s != user_id
      else
        relation = parent.actors.build(actor_id: user_id, actor_type: 'User', role: role)
        relation.save!
      end
    end if params['user']
    if parent.save
      flash[:notice] = t("flash.members.successfully_changed")
    else
      flash[:error] = t("flash.members.error_in_changing")
    end
    redirect_to group_members_path(parent)
  end

  def remove
    all_user_ids = []
    params['user_remove'].each do |user_id, remove|
      all_user_ids << user_id if remove == ["1"]
    end if params['user_remove']
    User.where(id: all_user_ids).each do |user|
      parent.remove_member(user)
    end
    redirect_to group_members_path(parent)
  end

  def add
    @user = User.find_by_uname(params[:user_uname])
    if !@user
      flash[:error] = t("flash.collaborators.wrong_user", uname: params[:user_uname])
    elsif parent.add_member(@user, params[:role])
      flash[:notice] = t("flash.members.successfully_added")
    else
      flash[:error] = t("flash.members.error_in_adding")
    end
    redirect_to group_members_path(parent)
  end
end
