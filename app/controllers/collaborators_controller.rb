class CollaboratorsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :find_project
  before_filter :find_users
  before_filter :find_groups

  load_and_authorize_resource :project

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
    all_user_ids = []
    all_groups_ids = []
    puts params.inspect
    Relation::ROLES.each { |r| 
      all_user_ids = all_user_ids | params['user'][r.to_sym].keys if params['user'] && params['user'][r.to_sym]
      all_groups_ids = all_groups_ids | params['group'][r.to_sym].keys if params['group'] && params['group'][r.to_sym]
    }

    # Remove relations
    users_for_removing = @project.collaborators.select do |u|
      !all_user_ids.map{|k| k.to_i}.include? u.id and @project.owner != u
    end
    users_for_removing.each do |u|
      Relation.by_object(u).by_target(@project).each {|r| r.destroy}
    end
    groups_for_removing = @project.groups.select do |u|
      !all_groups_ids.map{|k| k.to_i}.include? u.id and @project.owner != u
    end
    groups_for_removing.each do |u|
      Relation.by_object(u).by_target(@project).each {|r| r.destroy}
    end
    
    # Create relations
    Relation::ROLES.each { |r|
      #users_for_creating = users_for_creating params[:user].keys.map{|p| p.to_i} - @project.collaborators.map(&:id)
      params['user'][r.to_sym].keys.each { |u|
        if relation = @project.relations.find_by_object_id_and_object_type(u, 'User')
          relation.update_attribute(:role, r)
        else
          relation = @project.relations.build(:object_id => u, :object_type => 'User', :role => r)
          relation.save!
        end
      } if params['user'] && params['user'][r.to_sym]
      params['group'][r.to_sym].keys.each { |u|
        if relation = @project.relations.find_by_object_id_and_object_type(u, 'Group')
          relation.update_attribute(:role, r)
        else
          relation = @project.relations.build(:object_id => u, :object_type => 'Group', :role => r)
          relation.save!
        end
      } if params['group'] && params['group'][r.to_sym]
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

    def find_users
      @users = User.all
    end

    def find_groups
      @groups = Group.all
    end
end
