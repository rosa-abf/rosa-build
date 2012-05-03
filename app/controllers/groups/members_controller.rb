# -*- encoding : utf-8 -*-
class Groups::MembersController < Groups::BaseController
  is_related_controller!
  belongs_to :group, :finder => 'find_by_owner_name!', :optional => true

  before_filter lambda { authorize! :manage_members, @group }

  def index
  end

  def update
    params['user'].keys.each { |user_id|
      role = params['user'][user_id]

      if relation = parent.actors.where(:actor_id => user_id, :actor_type => 'User') #find_by_actor_id_and_actor_type(user_id, 'User')
        relation.update_all(:role => role) if parent.owner.id.to_s != user_id
      else
        relation = parent.actors.build(:actor_id => user_id, :actor_type => 'User', :role => role)
        relation.save!
      end
    } if params['user']
    if parent.save
      flash[:notice] = t("flash.members.successfully_changed")
    else
      flash[:error] = t("flash.members.error_in_changing")
    end
    redirect_to group_members_path(parent)
  end

  def remove
    all_user_ids = []
    params['user_remove'].keys.each { |user_id|
      all_user_ids << user_id if params['user_remove'][user_id] == ["1"] && parent.owner.id.to_s != user_id
    } if params['user_remove']
    all_user_ids.each do |user_id|
      u = User.find(user_id)
      Relation.by_actor(u).by_target(parent).each {|r| r.destroy}
    end
    redirect_to group_members_path(parent)
  end

  def add
    if params['user_id'] and !params['user_id'].empty?
      @user = User.find_by_uname(params['user_id'])
      unless parent.actors.exists? :actor_id => @user.id, :actor_type => 'User'
        relation = parent.actors.build(:actor_id => @user.id, :actor_type => 'User', :role => params[:role])
        if relation.save
          flash[:notice] = t("flash.members.successfully_added")
        else
          flash[:error] = t("flash.members.error_in_adding")
        end
      else
        flash[:error] = t("flash.members.already_added")
      end
    end
    redirect_to group_members_path(parent)
  end
end
