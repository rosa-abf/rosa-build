class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    # raise Pundit::NotAuthorizedError, 'must be logged in' unless user
    @user   = user || User.new
    @record = record
  end

  BASIC_ACTIONS = %i(index? show? create? update? destroy? destroy_all?)

  def index?
    false
  end

  def show?
    false
  end

  def new?
    create?
  end

  def edit?
    update?
  end

  def update?
    false
  end

  def create?
    false
  end

  def destroy?
    false
  end

  def permitted_attributes
    []
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      scope
    end

    # Public: Get user's group ids.
    #
    # Returns the Array of group ids.
    def user_group_ids
      Rails.cache.fetch(['ApplicationPolicy#user_group_ids', user.id]) do
        user.group_ids
      end
    end
  end

  protected

  # Public: Check if provided user is the current user.
  #
  # Returns true if it is, false otherwise.
  def current_user?(u)
    u == user
  end

  # Public: Check if provided user is guest.
  #
  # Returns true if he is, false otherwise.
  def is_guest?
    user.new_record?
  end

  # Public: Check if provided user is user.
  #
  # Returns true if he is, false otherwise.
  def is_user?
    user.persisted?
  end

  # Public: Check if provided user is tester.
  #
  # Returns true if he is, false otherwise.
  def is_tester?
    user.role == 'tester'
  end

  # Public: Check if provided user is system.
  #
  # Returns true if he is, false otherwise.
  def is_system?
    user.role == 'system'
  end

  # Public: Check if provided user is admin.
  #
  # Returns true if he is, false otherwise.
  def is_admin?
    user.role == 'admin'
  end

  # Public: Check if provided user is banned.
  #
  # Returns true if he is, false otherwise.
  def is_banned?
    user.role == 'banned'
  end

end