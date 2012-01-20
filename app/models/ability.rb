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

    if user.admin?
      can :manage, :all
      cannot :destroy, Subscribe
      cannot :create, Subscribe
    else
      # Shared rights between guests and registered users
      can :forbidden, Platform

      # TODO remove because auth callbacks skipped
      can :auto_build, Project
      can [:publish_build, :status_build, :pre_build, :post_build, :circle_build, :new_bbdt], BuildList

      if user.guest? # Guest rights
        can :create, User
      else # Registered user rights
        can [:show, :autocomplete_user_uname], User

        can [:show, :update], Settings::Notifier, :user_id => user.id

        can [:read, :create], Group
        can [:update, :manage_members], Group do |group|
          group.objects.exists?(:object_type => 'User', :object_id => user.id, :role => 'admin') # or group.owner_id = user.id
        end
        can :destroy, Group, :owner_id => user.id

        can :create, Project
        can :read, Project, :visibility => 'open'
        can :read, Project, :owner_type => 'User', :owner_id => user.id
        can :read, Project, :owner_type => 'Group', :owner_id => user.group_ids
        can(:read, Project, read_relations_for('projects')) {|project| local_reader? project}
        can(:write, Project) {|project| local_writer? project} # for grack
        can([:update, :manage_collaborators], Project) {|project| local_admin? project}
        can(:fork, Project) {|project| can? :read, project}
        can(:destroy, Project) {|project| owner? project}

        # TODO: Turn on AAA when it will be updated
        #can :create, AutoBuildList
        #can [:index, :destroy], AutoBuildList, :project_id => user.own_project_ids

        can :read, BuildList, :project => {:visibility => 'open'}
        can :read, BuildList, :project => {:owner_type => 'User', :owner_id => user.id}
        can :read, BuildList, :project => {:owner_type => 'Group', :owner_id => user.group_ids}
        can(:read, BuildList, read_relations_for('build_lists', 'projects')) {|build_list| can? :read, build_list.project}
        can(:create, BuildList) {|build_list| can? :write, build_list.project}
        can(:publish, BuildList) {|build_list| build_list.can_publish? && can?(:write, build_list.project)}

        can :read, Platform, :visibility => 'open'
        can :read, Platform, :owner_type => 'User', :owner_id => user.id
        can :read, Platform, :owner_type => 'Group', :owner_id => user.group_ids
        can(:read, Platform, read_relations_for('platforms')) {|platform| local_reader? platform}
        can(:update, Platform) {|platform| local_admin? platform}
        can([:freeze, :unfreeze, :destroy], Platform) {|platform| owner? platform}
        can :autocomplete_user_uname, Platform

        # TODO delegate to platform?
        can :read, Repository, :visibility => 'open'
        can :read, Repository, :owner_type => 'User', :owner_id => user.id
        can :read, Repository, :owner_type => 'Group', :owner_id => user.group_ids
        can(:read, Repository, read_relations_for('repositories')) {|repository| local_reader? repository}
        can(:create, Repository) {|repository| local_admin? repository.platform}
        can([:update, :add_project, :remove_project], Repository) {|repository| local_admin? repository}
        can([:change_visibility, :settings, :destroy], Repository) {|repository| owner? repository}

        can :read, Product, :platform => {:owner_type => 'User', :owner_id => user.id}
        can :read, Product, :platform => {:owner_type => 'Group', :owner_id => user.group_ids}
        can(:manage, Product, read_relations_for('products', 'platforms')) {|product| local_admin? product.platform}

        can [:read, :platforms], Category

        can [:read, :create], PrivateUser, :platform => {:owner_type => 'User', :owner_id => user.id}
        can [:read, :create], PrivateUser, :platform => {:owner_type => 'Group', :owner_id => user.group_ids}

        # can :read, Issue, :status => 'open'
        can :read, Issue, :project => {:visibility => 'open'}
        can :read, Issue, :project => {:owner_type => 'User', :owner_id => user.id}
        can :read, Issue, :project => {:owner_type => 'Group', :owner_id => user.group_ids}
        can(:read, Issue, read_relations_for('issues', 'projects')) {|issue| can? :read, issue.project rescue nil}
        can(:create, Issue) {|issue| can? :write, issue.project}
        can([:update, :destroy], Issue) {|issue| issue.user_id == user.id or local_admin?(issue.project)}
        cannot :manage, Issue, :project => {:has_issues => false} # switch off issues

        can(:create, Comment) {|comment| can? :read, comment.project || comment.commentable.project}
        can(:update, Comment) {|comment| comment.user_id == user.id or local_admin?(comment.project || comment.commentable.project)}
        #cannot :manage, Comment, :commentable => {:project => {:has_issues => false}} # switch off issues
        cannot(:manage, Comment) {|comment| comment.commentable_type == 'Issue' && !comment.commentable.project.has_issues} # switch off issues
      end
    end

    # Shared cannot rights for all users (guests, registered, admin)
    cannot :destroy, Platform, :platform_type => 'personal'
    cannot :destroy, Repository, :platform => {:platform_type => 'personal'}
    cannot :fork, Project, :owner_id => user.id, :owner_type => user.class.to_s
    cannot :destroy, Issue

    can :create, Subscribe do |subscribe|
      !subscribe.subscribeable.subscribes.exists?(:user_id => user.id)
    end
    can :destroy, Subscribe do |subscribe|
      subscribe.subscribeable.subscribes.exists?(:user_id => user.id) && user.id == subscribe.user_id
    end
  end

  # TODO group_ids ??
  def read_relations_for(table, parent = nil)
    key = parent ? "#{parent.singularize}_id" : 'id'
    parent ||= table
    ["#{table}.#{key} IN (
      SELECT target_id FROM relations WHERE relations.target_type = ? AND
      (relations.object_type = 'User' AND relations.object_id = ? OR
       relations.object_type = 'Group' AND relations.object_id IN (?)))", parent.classify, @user, @user.group_ids]
  end

  def relation_exists_for(object, roles)
    object.relations.exists?(:object_id => @user.id, :object_type => 'User', :role => roles) or
    object.relations.exists?(:object_id => @user.group_ids, :object_type => 'Group', :role => roles)
  end

  def local_reader?(object)
    relation_exists_for(object, %w{reader writer admin}) or owner?(object)
  end

  def local_writer?(object)
    relation_exists_for(object, %w{writer admin}) or owner?(object)
  end

  def local_admin?(object)
    relation_exists_for(object, 'admin') or owner?(object)
  end

  def owner?(object)
    object.owner == @user or @user.own_groups.include?(object.owner)
  end
end
