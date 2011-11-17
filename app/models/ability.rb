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
      can :read, [Project, Platform], :visibility => 'open'

      # Guest rights
      if user.guest?
        can :create, User
          
      # Registered user rights
      else
        # If rules goes one by one CanCan joins them by 'OR' sql operator
        can :read, Project, :visibility => 'open'
        # User can read and edit his profile:
        can :manage, User, :id => user.id

        # If rule has multiple conditions CanCan joins them by 'AND' sql operator
        can [:read, :update, :process_build, :build], Project, :owner_type => 'User', :owner_id => user.id
        #can :read, Project, :relations => {:role => 'read'}
        can :read, Project, projects_in_relations_with(:role => 'read', :object_type => 'User', :object_id => user.id)
        #can [:update, :process_build, :build], Project, :relations => {:role => 'write'}
        can [:update, :process_build, :build], Project, projects_in_relations_with(:role => 'write', :object_type => 'User', :object_id => user.id)
        
        can :read, Platform, :owner_type => 'User', :owner_id => user.id
        #can :read, Platform, :members => {:id => user.id}
        can :read, Platform, platforms_in_relations_with(:role => 'read', :object_type => 'User', :object_id => user.id)
        
        #can :read, Repository
        # TODO: Add personal repos rules
        
        # Same rights for groups:
        can [:read, :update, :process_build, :build], Project, :owner_type => 'Group', :owner_id => user.group_ids
        #can :read, Project, :relations => {:role => 'read', :object_type => 'Group', :object_id => user.group_ids}
        can :read, Project, projects_in_relations_with(:role => 'read', :object_type => 'Group', :object_id => user.group_ids)
        #can [:update, :process_build, :build], Project, :relations => {:role => 'write', :object_type => 'Group', :object_id => user.group_ids}
        can [:update, :process_build, :build], Project, projects_in_relations_with(:role => 'write', :object_type => 'Group', :object_id => user.group_ids)
        
        can :manage, Platform, :owner_type => 'Group', :owner_id => user.group_ids
        #can :read, Platform, :groups => {:id => user.group_ids}
        can :read, Platform, platforms_in_relations_with(:role => 'read', :object_type => 'Group', :object_id => user.group_ids)
      end
    end
    
    # Shared rights for all users (guests, registered, admin)
    cannot :destroy, Platform, :platform_type => 'personal'
  end

  # Sub query for platforms, projects relations
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