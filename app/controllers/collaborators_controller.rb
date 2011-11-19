class CollaboratorsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_project

  before_filter :find_roles
  before_filter :find_default_roles, :only => [:create, :update, :edit]
  before_filter :find_users
  before_filter :find_groups

  def index
    authorize! :manage_collaborators, @project
    
    redirect_to edit_project_collaborators_path(@project)
  end

  def show
  end

  def new
  end

  def edit
    authorize! :manage_collaborators, @project

    if params[:id]
      @user = User.find params[:id]
      render :edit_rights and return
    end
  end

  def create
  end

  def update
    authorize! :manage_collaborators, @project

    all_user_ids = []
    Relation::ROLES.each { |r| 
      all_user_ids = all_user_ids | params[r.to_sym].keys if params[r.to_sym]
    }

    # Remove relations
    users_for_removing = @project.collaborators.select do |u|
      !all_user_ids.map{|k| k.to_i}.include? u.id and @project.owner != u
    end
    users_for_removing.each do |u|
      Relation.by_object(u).by_target(@project).each {|r| r.destroy}
    end
    
    # Create relations
    Relation::ROLES.each { |r|
      #users_for_creating = users_for_creating params[:user].keys.map{|p| p.to_i} - @project.collaborators.map(&:id)
      params[r.to_sym].keys.each { |u|
        if relation = @project.relations.find_by_object_id_and_object_type(u, 'User')
          relation.update_attribute(:role, r)
        else
          relation = @project.relations.build(:object_id => u, :object_type => 'User', :role => r)
          puts relation.inspect
          puts r
          relation.save!
        end
      } if params[r.to_sym]
    }

    if @project.save
      flash[:notice] = t("flash.collaborators.successfully_changed")
    else
      flash[:error] = t("flash.collaborators.error_in_changing")
    end
    redirect_to project_path(@project)
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
