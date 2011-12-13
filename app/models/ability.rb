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

      can :read, [Repository, Platform], :visibility => 'open'
      # TODO remove because auth callbacks skipped
      can :auto_build, Project
      can [:status_build, :pre_build, :post_build, :circle_build, :new_bbdt], BuildList

      # Guest rights
      if user.guest?
        can :create, User
      # Registered user rights
      else
        can [:read, :platforms], Category

        can :create, AutoBuildList
        can [:index, :destroy], AutoBuildList, :project_id => user.own_project_ids
        # If rules goes one by one CanCan joins them by 'OR' sql operator
        can :read, Project, :visibility => 'open'
        can :read, Group
        can :read, User
        can :manage_collaborators, Project do |project|
          project.relations.exists? :object_id => user.id, :object_type => 'User', :role => 'admin'
        end
        can :manage_members, Group do |group|
          group.objects.exists? :object_id => user.id, :object_type => 'User', :role => 'admin'
        end

        # Put here model names which objects can user create
        can :create, Project
        can :create, Group
        can :publish, BuildList do |build_list|
          build_list.can_published? && build_list.project.relations.exists?(:object_type => 'User', :object_id => user.id)
        end
        can :shoe, BuildList do |build_list|
          build_list.project.public? || build_list.project.relations.exists?(:object_type => 'User', :object_id => user.id)
        end
        can [:read, :create], PrivateUser, :platform => {:owner_type => 'User', :owner_id => user.id}

        # If rule has multiple conditions CanCan joins them by 'AND' sql operator
        can [:read, :update, :process_build, :build, :destroy], Project, :owner_type => 'User', :owner_id => user.id
        #can :read, Project, :relations => {:role => 'reader'}
        can :read, Project, projects_in_relations_with(:role => 'reader', :object_type => 'User', :object_id => user.id) do |project|
          #The can? and cannot? call cannot be used with a raw sql 'can' definition.
          project.relations.exists?(:role => 'reader', :object_type => 'User', :object_id => user.id)
        end
        #can [:update, :process_build, :build], Project, :relations => {:role => 'writer'}
        can [:read, :update, :process_build, :build], Project, projects_in_relations_with(:role => ['writer', 'admin'], :object_type => 'User', :object_id => user.id)  do |project|
          project.relations.exists?(:role => ['writer', 'admin'], :object_type => 'User', :object_id => user.id)
        end

        can [:read, :update, :destroy], Product, products_in_relations_with(:role => ['writer', 'admin'], :object_type => 'User', :object_id => user.id)  do |product|
          product.relations.exists?(:role => 'admin', :object_type => 'User', :object_id => user.id)
        end
        # Small CanCan hack by Product.new(:platform_id => ...)
        can [:new, :create], Product do |product|
          product.platform.relations.exists?(:role => 'admin', :object_type => 'User', :object_id => user.id)
        end

        can [:read, :update], Group, groups_in_relations_with(:role => ['writer', 'admin'], :object_type => 'User', :object_id => user.id) do |group|
          group.objects.exists?(:role => ['writer', 'admin'], :object_type => 'User', :object_id => user.id)
        end
        
        can :manage, Platform, :owner_type => 'User', :owner_id => user.id
        can :manage, Platform, platforms_in_relations_with(:role => 'admin', :object_type => 'User', :object_id => user.id) do |platform|
          platform.relations.exists?(:role => 'admin', :object_type => 'User', :object_id => user.id)
        end
        #can :read, Platform, :members => {:id => user.id}
        can :read, Platform, platforms_in_relations_with(:role => 'reader', :object_type => 'User', :object_id => user.id) do |platform|
          platform.relations.exists?(:role => 'reader', :object_type => 'User', :object_id => user.id)
        end

        can [:manage, :add_project, :remove_project, :change_visibility, :settings], Repository, :owner_type => 'User', :owner_id => user.id
        can :manage, Repository, repositories_in_relations_with(:role => 'admin', :object_type => 'User', :object_id => user.id) do |repository|
          repository.relations.exists?(:role => 'admin', :object_type => 'User', :object_id => user.id)
        end
        #can :read, Repository, :members => {:id => user.id}
        can :read, Repository, repositories_in_relations_with(:role => 'reader', :object_type => 'User', :object_id => user.id) do |repository|
          repository.relations.exists?(:role => 'reader', :object_type => 'User', :object_id => user.id)
        end
        # Small CanCan hack by Repository.new(:platform_id => ...)
        can [:new, :create], Repository do |repository|
          repository.platform.relations.exists?(:role => 'admin', :object_type => 'User', :object_id => user.id)
        end
        
        #can :read, Repository
        # TODO: Add personal repos rules
        
        # Same rights for groups:
        can [:read, :create], PrivateUser, :platform => {:owner_type => 'Group', :owner_id => user.group_ids}
        can :publish, BuildList do |build_list|
          build_list.can_published? && build_list.project.relations.exists?(:object_type => 'Group', :object_id => user.group_ids)
        end
        can :publish, BuildList do |build_list|
          build_list.project.public? || build_list.project.relations.exists?(:object_type => 'Group', :object_id => user.group_ids)
        end

        can :manage_collaborators, Project, projects_in_relations_with(:role => 'admin', :object_type => 'Group', :object_id => user.group_ids) do |project|
          project.relations.exists? :object_id => user.group_ids, :object_type => 'Group', :role => 'admin'
        end

        can [:read, :update, :process_build, :build, :destroy], Project, :owner_type => 'Group', :owner_id => user.group_ids
        #can :read, Project, :relations => {:role => 'reader', :object_type => 'Group', :object_id => user.group_ids}
        can :read, Project, projects_in_relations_with(:role => 'reader', :object_type => 'Group', :object_id => user.group_ids) do |project|
          project.relations.exists?(:role => 'reader', :object_type => 'Group', :object_id => user.group_ids)
        end
        #can [:update, :process_build, :build], Project, :relations => {:role => 'writer', :object_type => 'Group', :object_id => user.group_ids}
        can [:read, :update, :process_build, :build], Project, projects_in_relations_with(:role => ['writer', 'admin'], :object_type => 'Group', :object_id => user.group_ids) do |project|
          project.relations.exists?(:role => ['writer', 'admin'], :object_type => 'Group', :object_id => user.group_ids)
        end
        
        can :manage, Platform, :owner_type => 'Group', :owner_id => user.group_ids
        #can :read, Platform, :groups => {:id => user.group_ids}
        can :read, Platform, platforms_in_relations_with(:role => 'reader', :object_type => 'Group', :object_id => user.group_ids) do |platform|
          platform.relations.exists?(:role => 'reader', :object_type => 'Group', :object_id => user.group_ids)
        end

        can [:manage, :add_project, :remove_project], Repository, :owner_type => 'Group', :owner_id => user.group_ids
        #can :read, Platform, :groups => {:id => user.group_ids}
        can :read, Repository, repositories_in_relations_with(:role => 'reader', :object_type => 'Group', :object_id => user.group_ids) do |repository|
          repository.relations.exists?(:role => 'reader', :object_type => 'Group', :object_id => user.group_ids)
        end

        can(:fork, Project) {|p| can? :read, p}

        # Things that can not do simple user
        cannot :create, [Platform, User]
      end
    end
    
    # Shared cannot rights for all users (guests, registered, admin)
    cannot :destroy, Platform, :platform_type => 'personal'
    cannot :destroy, Repository, :platform => {:platform_type => 'personal'}
    cannot :fork, Project, :owner_id => user.id, :owner_type => user.class.to_s
  end

  # Sub query for platforms, projects relations
  # TODO: Replace table names list by method_missing way
  %w[platforms projects products repositories groups].each do |table_name|
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
