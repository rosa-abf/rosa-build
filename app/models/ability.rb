class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    if user.admin?
      can :manage, :all
    else
      # Block access to all objects on the site
      cannot :read, :all
      
      # Shared rights between guests and registered users
      can :read, Platform
      
      # Guest rights
      if user.guest?
        can :read, Project, :visibility => 'open'
      
      # Registered user rights
      else
        # If rule has multiple conditions CanCan joins them by 'AND' sql operator
        can [:read, :update, :process_build, :build], Project, :owner_type => 'User', :owner_id => user.id
        # If rules goes one by one CanCan joins them by 'OR' sql operator
        can :read, Project, :visibility => 'open'
        can [:read, :update, :process_build, :build], Project, :collaborators => {:id => user.id}
      end
    end
  end
end