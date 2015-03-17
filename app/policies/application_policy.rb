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
  end

  # Public: Get user's group ids.
  #
  # Returns the Array of group ids.
  def user_group_ids
    Rails.cache.fetch(['ApplicationPolicy#user_group_ids', user]) do
      user.group_ids
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

  # Private: Check if provided user is at least record admin.
  #
  # Returns true if he is, false otherwise.
  def local_admin?(r = record)
    best_role(r) == 'admin'
  end

  # Private: Check if provided user is at least record reader.
  #
  # Returns true if he is, false otherwise.
  def local_reader?(r = record)
    %w(reader writer admin).include? best_role(r)
  end

  # Private: Check if provided user is at least record writer.
  #
  # Returns true if he is, false otherwise.
  def local_writer?(r = record)
    %w(writer admin).include? best_role(r)
  end

  # Private: Check if provided user is record owner.
  #
  # Returns true if he is, false otherwise.
  def owner?
    (
      !record.try(:owner_type) && record.owner_id == user.id
    ) || (
      record.try(:owner_type) == 'User'  && record.owner_id == user.id
    ) || (
      record.try(:owner_type) == 'Group' && user_own_group_ids.include?(record.owner_id)
    )
  end

  # Private: Get the best role of user for record.
  #
  # Returns the String role or nil.
  def best_role(r = record)
    Rails.cache.fetch(['ApplicationPolicy#best_role', r, user]) do
      user.best_role(r)
    end
  end

  # Public: Get own user's group ids.
  #
  # Returns the Array of own group ids.
  def user_own_group_ids
    Rails.cache.fetch(['ApplicationPolicy#user_own_group_ids', user]) do
      user.own_group_ids
    end
  end

end