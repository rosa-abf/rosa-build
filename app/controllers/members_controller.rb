# -*- encoding : utf-8 -*-
class MembersController < ApplicationController
  before_filter :authenticate_user!
  is_related_controller!

  belongs_to :group, :optional => true

#  before_filter :find_target
  before_filter :find_users

  def index
    redirect_to edit_group_members_path(parent)
  end

  def show
  end

  def new
  end

  def edit
    if params[:id]
      @user = User.find params[:id]
      render :edit_rights and return
    end
    @group = parent
  end

  def create
  end

  def update
    params['user'].keys.each { |user_id|
      role = params['user'][user_id]

      if relation = parent.actors.where(:actor_id => user_id, :actor_type => 'User') #find_by_actor_id_and_actor_type(user_id, 'User')
        relation.update_attribute(:role, role)
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

    redirect_to edit_group_members_path(parent)
  end

  def remove
    if params[:id]
      u = User.find(params[:id])
      Relation.by_actor(u).by_target(parent)[0].destroy

      redirect_to groups_path
    else
      all_user_ids = []

      params['user_remove'].keys.each { |user_id|
        all_user_ids << user_id if params['user_remove'][user_id] == ["1"]
      } if params['user_remove']

      all_user_ids.each do |user_id|
        u = User.find(user_id)
        Relation.by_actor(u).by_target(parent).each {|r| r.destroy}
      end

      redirect_to edit_group_members_path(parent)
    end
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
    redirect_to edit_group_members_path(parent)
  end

  protected

    def find_users
      @users = parent.members #User.all
    end

end
