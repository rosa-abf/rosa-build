class CollaboratorsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_global_access

  before_filter :find_project

  before_filter :find_roles
  before_filter :find_default_roles, :only => [:create, :update, :edit]
  before_filter :find_users
  before_filter :find_groups

  def index
    redirect_to edit_project_collaborators_path(@project)
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
    unless params[:id]
      if params[:user]
        users_for_removing = @project.collaborators.select do |u|
          !params[:user].keys.map{|k| k.to_i}.include? u.id and @project.owner != u
        end
        users_for_creating = params[:user].keys.map{|p| p.to_i} - @project.collaborators.map(&:id)

        puts users_for_removing.inspect
        puts users_for_creating.inspect

        users_for_removing.each do |u|
          Relation.by_object(u).by_target(@project).each {|r| r.destroy}
        end
#        @project.collaborators.delete_if{|c| users_for_removing.include? c}
        users_for_creating.each do |user|
          @project.add_roles_to User.find(user), @def_user_roles
        end
      end
  #    if params[:group]
  #      groups_for_removing = @project.groups.select do |g|
  #        !params[:group].keys.map{|k| k.to_i}.include? g.id and @project.owner != g
  #      end
  #      groups_for_creating = params[:group].keys.map{|p| p.to_i} - @project.groups.map(&:id)
  #
  #      puts groups_for_removing.inspect
  #      puts groups_for_creating.inspect
  #
  #      @project.groups.delete_if{|g| groups_for_removing.include? g}
  #      groups_for_creating.each do |group|
  #        @project.add_roles_to Group.find(group), @def_group_roles
  #      end
  #    end
      if @project.save
        flash[:notice] = t("flash.collaborators.successfully_changed")
      else
        flash[:error] = t("flash.collaborators.error_in_changing")
      end
      redirect_to project_path(@project)
    else
      @user = User.find params[:id]
      if params[:role]
        roles_for_removing = @user.roles_to(@project).select do |r|
          !params[:role].keys.map{|k| k.to_i}.include? r.id
        end
        roles_for_creating = params[:role].keys.map{|r| r.to_i} - @user.roles_to(@project).map(&:id)

        puts roles_for_removing.inspect
        puts roles_for_creating.inspect

        roles_for_removing.each do |r|
          Relation.by_object(@user).by_target(@project).each do |rel|
            RoleLine.where(:role_id => r.id).where(:relation_id => rel.id).each {|rl| rl.destroy}
          end
        end
        @project.add_roles_to @user, Role.find(roles_for_creating)
      end
#      if @user.save!
        flash[:notice] = t("flash.collaborators.successfully_changed")
#      else
#        flash[:error] = t("flash.collaborators.error_in_changing")
#      end
      redirect_to edit_project_collaborators_path(@project)
    end
  end

  def destroy
  end

  protected

    def find_project
      @project = Project.find params[:project_id]
    end

    def find_roles
      @user_roles = Role.by_acter(User).by_target(Project) + Role.by_acter(:all).by_target(Project)
      @group_roles = Role.by_acter(Group).by_target(Project) + Role.by_acter(:all).by_target(Project)
    end

    def find_default_roles
      @def_user_roles = Role.by_acter(User).by_target(Project).default + Role.by_acter(:all).by_target(Project).default
      @def_group_roles = Role.by_acter(Group).by_target(Project).default + Role.by_acter(:all).by_target(Project).default
    end

    def find_users
      @users = User.all
    end

    def find_groups
      @groups = Group.all
    end
end
