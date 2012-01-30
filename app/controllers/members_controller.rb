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
  end

  def create
  end

  def update
    all_user_ids = []
    Relation::ROLES.each { |r| 
      all_user_ids = all_user_ids | params[r.to_sym].keys if params[r.to_sym]
    }

    # Remove relations
    users_for_removing = parent.members.select do |u|
      !all_user_ids.map{|k| k.to_i}.include? u.id and parent.owner != u
    end
    users_for_removing.each do |u|
      Relation.by_object(u).by_target(parent).each {|r| r.destroy}
    end

    # Create relations
    Relation::ROLES.each { |r|
      #users_for_creating = users_for_creating params[:user].keys.map{|p| p.to_i} - @project.collaborators.map(&:id)
      params[r.to_sym].keys.each { |u|
        if relation = parent.objects.find_by_object_id_and_object_type(u, 'User')
          relation.update_attribute(:role, r)
        else
          relation = parent.objects.build(:object_id => u, :object_type => 'User', :role => r)
          puts relation.inspect
          puts r
          relation.save!
        end
      } if params[r.to_sym]
    }

    if parent.save
      flash[:notice] = t("flash.members.successfully_changed")
    else
      flash[:error] = t("flash.members.error_in_changing")
    end
    redirect_to parent_path
  end

  def destroy
  end

  def add
    if params['user_id'] and !params['user_id'].empty?
      @user = User.find_by_uname(params['user_id'])
      unless parent.objects.exists? :object_id => @user.id, :object_type => 'User'
        relation = parent.objects.build(:object_id => @user.id, :object_type => 'User', :role => 'reader')
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
