class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    
    if user.admin?
      can :manage, :all
    else
      #WARNING:
      # - put cannot rules _after_ can rules and not before!
      # - beware inner joins. Use sub queries against them! 
      # Shared rights between guests and registered users
      can :forbidden, Platform

      #cannot :read, Platform, :visibility => 'hidden'
      can :read, [Repository, Platform], :visibility => 'open'
      can :auto_build, Project # TODO: This needs to be checked!
      can [:status_build, :pre_build, :post_build, :circle_build, :new_bbdt], BuildList

      # Guest rights
      if user.guest?
        can :create, User
          
      # Registered user rights
      else
        can :index, AutoBuildList
        # If rules goes one by one CanCan joins them by 'OR' sql operator
        can :read, Project, :visibility => 'open'
        can :read, User
        can :manage_collaborators, Project do |project|
          project.relations.exists? :object_id => user.id, :object_type => 'User', :role => 'admin'
        end
        # Put here model names which objects can user create
        can :create, Project
        can :publish, BuildList do |build_list|
          build_list.can_published? && build_list.project.relations.exists?(:object_type => 'User', :object_id => user.id)
        end
        can [:read, :create], PrivateUser, :platform => {:owner_type => 'User', :owner_id => user.id}

        # If rule has multiple conditions CanCan joins them by 'AND' sql operator
        can [:read, :update, :process_build, :build, :destroy], Project, :owner_type => 'User', :owner_id => user.id
        #can :read, Project, :relations => {:role => 'read'}
        can :read, Project, projects_in_relations_with(:role => 'read', :object_type => 'User', :object_id => user.id) do |project|
          #The can? and cannot? call cannot be used with a raw sql 'can' definition.
          project.relations.exists?(:role => 'read', :object_type => 'User', :object_id => user.id)
        end
        #can [:update, :process_build, :build], Project, :relations => {:role => 'write'}
        can [:read, :update, :process_build, :build], Project, projects_in_relations_with(:role => ['write', 'admin'], :object_type => 'User', :object_id => user.id)  do |project|
          project.relations.exists?(:role => ['write', 'admin'], :object_type => 'User', :object_id => user.id)
        end
        
        can :manage, Platform, :owner_type => 'User', :owner_id => user.id
        #can :read, Platform, :members => {:id => user.id}
        can :read, Platform, platforms_in_relations_with(:role => 'read', :object_type => 'User', :object_id => user.id) do |platform|
          platform.relations.exists?(:role => 'read', :object_type => 'User', :object_id => user.id)
        end

        can [:manage, :add_project, :remove_project, :change_visibility, :settings], Repository, :owner_type => 'User', :owner_id => user.id
        #can :read, Platform, :members => {:id => user.id}
        can :read, Repository, repositories_in_relations_with(:role => 'read', :object_type => 'User', :object_id => user.id) do |repository|
          repository.relations.exists?(:role => 'read', :object_type => 'User', :object_id => user.id)
        end
        
        #can :read, Repository
        # TODO: Add personal repos rules
        
        # Same rights for groups:
        can [:read, :create], PrivateUser, :platform => {:owner_type => 'Group', :owner_id => user.group_ids}
        can :publish, BuildList do |build_list|
          build_list.can_published? && build_list.project.relations.exists?(:object_type => 'Group', :object_id => user.group_ids)
        end

        can [:read, :update, :process_build, :build, :destroy], Project, :owner_type => 'Group', :owner_id => user.group_ids
        #can :read, Project, :relations => {:role => 'read', :object_type => 'Group', :object_id => user.group_ids}
        can :read, Project, projects_in_relations_with(:role => 'read', :object_type => 'Group', :object_id => user.group_ids) do |project|
          project.relations.exists?(:role => 'read', :object_type => 'Group', :object_id => user.group_ids)
        end
        #can [:update, :process_build, :build], Project, :relations => {:role => 'write', :object_type => 'Group', :object_id => user.group_ids}
        can [:read, :update, :process_build, :build], Project, projects_in_relations_with(:role => ['write', 'admin'], :object_type => 'Group', :object_id => user.group_ids) do |project|
          project.relations.exists?(:role => ['write', 'admin'], :object_type => 'Group', :object_id => user.group_ids)
        end
        
        can :manage, Platform, :owner_type => 'Group', :owner_id => user.group_ids
        #can :read, Platform, :groups => {:id => user.group_ids}
        can :read, Platform, platforms_in_relations_with(:role => 'read', :object_type => 'Group', :object_id => user.group_ids) do |platform|
          platform.relations.exists?(:role => 'read', :object_type => 'Group', :object_id => user.group_ids)
        end

        can [:manage, :add_project, :remove_project], Repository, :owner_type => 'Group', :owner_id => user.group_ids
        #can :read, Platform, :groups => {:id => user.group_ids}
        can :read, Repository, repositories_in_relations_with(:role => 'read', :object_type => 'Group', :object_id => user.group_ids) do |repository|
          repository.relations.exists?(:role => 'read', :object_type => 'Group', :object_id => user.group_ids)
        end

        # Things that can not do simple user
        cannot :create, [Platform, User, Repository]
      end
    end
    
    # Shared cannot rights for all users (guests, registered, admin)
    cannot :destroy, Platform, :platform_type => 'personal'
    cannot :destroy, Repository, :platform => {:platform_type => 'personal'}
  end

  # Sub query for platforms, projects relations
  # TODO: Replace table names list by method_missing way
  %w[platforms projects repositories].each do |table_name|
    define_method table_name + "_in_relations_with" do |opts|
      query = "#{ table_name }.id IN (SELECT target_id FROM relations WHERE relations.target_type = '#{ table_name.singularize.camelize }'"
      opts.each do |key, value|
        query = query + " AND relations.#{ key } #{ value.class == Array ? 'IN (?)' : '= ?' } "
      end
      query = query + ")"

      return opts.values.unshift query
    end
  end

  ## Sub query for project relations
  #def projects_in_relations_with(opts={})
  #  ["projects.id IN (SELECT target_id FROM relations WHERE relations.object_id #{ opts[:object_id].class == Array ? 'IN (?)' : '= ?' } AND relations.object_type = '#{ opts[:object_type] }' AND relations.target_type = 'Platform') AND relations.role", opts[:object_id]]
  #end
end