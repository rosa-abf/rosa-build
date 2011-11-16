class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    
    if user.admin?
      can :manage, :all
    else
      # Shared rights between guests and registered users
      can :read, Platform
      can :index, [Platform, Project, User, Category, Download]
      can :forbidden, Platform
      cannot :read, Platform, :visibility => 'hidden'
      cannot :read, Platform, :platform_type => 'personal'
      
      # Guest rights
      if user.guest?
        can :read, Project, :visibility => 'open'
      
      # Registered user rights
      else
        # If rule has multiple conditions CanCan joins them by 'AND' sql operator
        can [:read, :update, :process_build, :build], Project, :owner_type => 'User', :owner_id => user.id
        # If rules goes one by one CanCan joins them by 'OR' sql operator
        can :read, Project, :visibility => 'open'
        #can [:read, :update, :process_build, :build], Project, :collaborators => {:id => user.id}
        can :read, Project, :relations => {:role => 'read'}
        can [:update, :process_build, :build], Project, :relations => {:role => 'write'}
        
        can :manage, Platform, :owner_type => 'User', :owner_id => user.id
        can :read, Platform, :members => {:id => user.id}
        
        #can :read, Repository
        # TODO: Add personal repos rules
        
        # Same rights for groups:
        can [:read, :update, :process_build, :build], Project, :owner_type => 'Group', :owner_id => user.group_ids
        can :read, Project, :relations => {:role => 'read', :object_type => 'Group', :object_id => user.group_ids}
        can [:update, :process_build, :build], Project, :relations => {:role => 'write', :object_type => 'Group', :object_id => user.group_ids}
        
        can :manage, Platform, :owner_type => 'Group', :owner_id => user.group_ids
        can :read, Platform, :groups => {:id => user.group_ids}
      end
    end
    
    # Shared rights for all users (guests, registered, admin)
    cannot :destroy, Platform, :platform_type => 'personal'
  end
end