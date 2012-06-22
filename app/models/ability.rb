# -*- encoding : utf-8 -*-
# If rules goes one by one CanCan joins them by 'OR' sql operator
# If rule has multiple conditions CanCan joins them by 'AND' sql operator
# WARNING:
# - put cannot rules _after_ can rules and not before!
# - beware inner joins. Use sub queries against them!

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    @user = user

    # Shared rights between guests and registered users
    can :show, Project, :visibility => 'open'
    can :archive, Project, :visibility => 'open'
    can :read, Issue, :project => {:visibility => 'open'}
    can :search, BuildList
    can :read, BuildList, :project => {:visibility => 'open'}
    can :read, ProductBuildList, :product => {:platform => {:visibility => 'open'}}
    can :read, Advisory
    can(:advisories, Platform) {APP_CONFIG['anonymous_access']}
    # Core callbacks
    can [:publish_build, :status_build, :pre_build, :post_build, :circle_build, :new_bbdt], BuildList

    if user.guest? # Guest rights
      # can [:new, :create], RegisterRequest
    else # Registered user rights
      if user.admin?
        can :manage, :all
        # Protection
        cannot :approve, RegisterRequest, :approved => true
        cannot :reject, RegisterRequest, :rejected => true
        cannot [:destroy, :create], Subscribe
        # Act admin as simple user
        cannot :read, Product, :platform => {:platform_type => 'personal'}
        cannot [:owned, :related], [BuildList, Platform]
        cannot :membered, Project # list products which user members
      end

      if user.user?
        can [:show, :autocomplete_user_uname], User

        can [:read, :create, :autocomplete_group_uname], Group
        can [:update, :manage_members], Group do |group|
          group.actors.exists?(:actor_type => 'User', :actor_id => user.id, :role => 'admin') # or group.owner_id = user.id
        end
        can :destroy, Group, :owner_id => user.id
        can :remove_user, Group

        can :create, Project
        can :read, Project, :visibility => 'open'
        can [:read, :archive], Project, :owner_type => 'User', :owner_id => user.id
        can [:read, :archive], Project, :owner_type => 'Group', :owner_id => user.group_ids
        can([:read, :membered], Project, read_relations_for('projects')) {|project| local_reader? project}
        can(:write, Project) {|project| local_writer? project} # for grack
        can([:update, :sections, :manage_collaborators], Project) {|project| local_admin? project}
        can(:fork, Project) {|project| can? :read, project}
        can(:fork, Project) {|project| project.owner_type == 'Group' and can? :update, project.owner}
        can(:destroy, Project) {|project| owner? project}
        can(:destroy, Project) {|project| project.owner_type == 'Group' and project.owner.actors.exists?(:actor_type => 'User', :actor_id => user.id, :role => 'admin')}
        can :remove_user, Project

        can [:read, :owned], BuildList, :user_id => user.id
        can [:read, :related], BuildList, :project => {:owner_type => 'User', :owner_id => user.id}
        can [:read, :related], BuildList, :project => {:owner_type => 'Group', :owner_id => user.group_ids}
        can(:read, BuildList, read_relations_for('build_lists', 'projects')) {|build_list| can? :read, build_list.project}
        can([:create, :update], BuildList) {|build_list| build_list.project.is_package && can?(:write, build_list.project)}

        can(:publish, BuildList) do |build_list|
          build_list.can_publish? and build_list.save_to_platform.released ? local_admin?(build_list.save_to_platform) : can?(:write, build_list.project)
        end
        can(:reject_publish, BuildList) do |build_list|
          build_list.can_reject_publish? and build_list.save_to_platform.released and local_admin?(build_list.save_to_platform)
        end
        can(:cancel, BuildList) {|build_list| build_list.can_cancel? && can?(:write, build_list.project)}

        can [:read], Advisory

        can [:read, :members], Platform, :visibility => 'open'
        can [:read, :owned, :related, :members], Platform, :owner_type => 'User', :owner_id => user.id
        can [:read, :related, :members], Platform, :owner_type => 'Group', :owner_id => user.group_ids
        can([:read, :related, :members], Platform, read_relations_for('platforms')) {|platform| local_reader? platform}
        can([:update, :members], Platform) {|platform| local_admin? platform}
        can([:destroy, :members, :add_member, :remove_member, :remove_members, :build_all, :mass_builds] , Platform) {|platform| owner? platform}
        can [:autocomplete_user_uname, :read_advisories, :advisories], Platform

        can [:read, :projects_list], Repository, :platform => {:visibility => 'open'}
        can [:read, :projects_list], Repository, :platform => {:owner_type => 'User', :owner_id => user.id}
        can [:read, :projects_list], Repository, :platform => {:owner_type => 'Group', :owner_id => user.group_ids}
        can([:read, :projects_list], Repository, read_relations_for('repositories', 'platforms')) {|repository| local_reader? repository.platform}
        can([:create, :update, :projects_list, :add_project, :remove_project, :erase], Repository) {|repository| local_admin? repository.platform}
        can([:change_visibility, :settings, :destroy], Repository) {|repository| owner? repository.platform}

        can :read, Product, :platform => {:visibility => 'open'}
        can :read, Product, :platform => {:owner_type => 'User', :owner_id => user.id, :platform_type => 'main'}
        can :read, Product, :platform => {:owner_type => 'Group', :owner_id => user.group_ids, :platform_type => 'main'}
        can(:read, Product, read_relations_for('products', 'platforms')) {|product| product.platform.platform_type == 'main'}
        can([:create, :update, :destroy, :clone], Product) {|product| local_admin? product.platform and product.platform.platform_type == 'main'}

        can(:create, ProductBuildList) {|pbl| can?(:update, pbl.product)}
        can(:destroy, ProductBuildList) {|pbl| can?(:destroy, pbl.product)}

        can [:read, :create], PrivateUser, :platform => {:owner_type => 'User', :owner_id => user.id}
        can [:read, :create], PrivateUser, :platform => {:owner_type => 'Group', :owner_id => user.group_ids}

        can :read, Issue, :project => {:owner_type => 'User', :owner_id => user.id}
        can :read, Issue, :project => {:owner_type => 'Group', :owner_id => user.group_ids}
        can(:read, Issue, read_relations_for('issues', 'projects')) {|issue| can? :read, issue.project rescue nil}
        can(:create, Issue) {|issue| can? :write, issue.project}
        can([:update, :destroy], Issue) {|issue| issue.user_id == user.id or local_admin?(issue.project)}
        cannot :manage, Issue, :project => {:has_issues => false} # switch off issues

        can(:create, Comment) {|comment| can? :read, comment.project}
        can(:update, Comment) {|comment| comment.user_id == user.id or local_admin?(comment.project || comment.commentable.project)}
        cannot :manage, Comment, :commentable_type => 'Issue', :commentable => {:project => {:has_issues => false}} # switch off issues
      end

      # Shared cannot rights for all users (registered, admin)
      cannot :destroy, Platform, :platform_type => 'personal'
      cannot [:create, :destroy, :add_project, :remove_project, :erase], Repository, :platform => {:platform_type => 'personal'}
      cannot :destroy, Issue

      cannot [:members, :add_member, :remove_member, :remove_members], Platform, :platform_type => 'personal'

      cannot [:create, :update, :destroy, :clone], Product, :platform => {:platform_type => 'personal'}
      cannot [:clone, :build_all, :mass_builds], Platform, :platform_type => 'personal'

      can :create, Subscribe do |subscribe|
        !subscribe.subscribeable.subscribes.exists?(:user_id => user.id)
      end
      can :destroy, Subscribe do |subscribe|
        subscribe.subscribeable.subscribes.exists?(:user_id => user.id) && user.id == subscribe.user_id
      end
    end
  end

  # TODO group_ids ??
  def read_relations_for(table, parent = nil)
    key = parent ? "#{parent.singularize}_id" : 'id'
    parent ||= table
    ["#{table}.#{key} IN (
      SELECT target_id FROM relations WHERE relations.target_type = ? AND
      (relations.actor_type = 'User' AND relations.actor_id = ? OR
       relations.actor_type = 'Group' AND relations.actor_id IN (?)))", parent.classify, @user, @user.group_ids]
  end

  def relation_exists_for(target, roles)
    target.relations.exists?(:actor_id => @user.id, :actor_type => 'User', :role => roles) or
    target.relations.exists?(:actor_id => @user.group_ids, :actor_type => 'Group', :role => roles)
  end

  def local_reader?(target)
    relation_exists_for(target, %w{reader writer admin}) or owner?(target)
  end

  def local_writer?(target)
    relation_exists_for(target, %w{writer admin}) or owner?(target)
  end

  def local_admin?(target)
    relation_exists_for(target, 'admin') or owner?(target)
  end

  def owner?(target)
    target.owner == @user or @user.own_groups.include?(target.owner)
  end
end
