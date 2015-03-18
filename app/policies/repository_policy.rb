class RepositoryPolicy < ApplicationPolicy

  def show?
    policy(record.platform).show?
  end
  alias_method :projects?,      :show?
  alias_method :projects_list?, :show?
  alias_method :read?,          :show?

  def reader?
    local_reader?(record.platform)
  end

  def write?
    local_writer?(record.platform)
  end

  def update?
    local_admin?(record.platform)
  end
  alias_method :manage_members?,        :update?
  alias_method :regenerate_metadata?,   :update?
  alias_method :signatures?,            :update?

  def create?
    return false if record.platform.personal? && name == 'main'
    local_admin?(record.platform)
  end
  alias_method :destroy?, :create?

  def packages?
    record.platform.main? && local_admin?(record.platform)
  end
  alias_method :remove_member?,         :packages?
  alias_method :remove_members?,        :packages?
  alias_method :add_member?,            :packages?
  alias_method :sync_lock_file?,        :packages?

  def add_project?
    local_admin?(record.platform) || repository_user_ids.include?(user.id)
  end
  alias_method :remove_project?, :add_project?

  def destroy?
    owner?(record.platform)
  end
  alias_method :settings?, :destroy?

  def key_pair?
    user.system?
  end

  def add_repo_lock_file?
    user.system? || ( record.platform.main? && local_admin?(record.platform) )
  end
  alias_method :remove_repo_lock_file?, :add_repo_lock_file?

private

  # Public: Get user ids of repository.
  #
  # Returns the Set of user ids.
  def repository_user_ids
    Rails.cache.fetch(['RepositoryPolicy#repository_user_ids', record]) do
      Set.new record.member_ids
    end
  end

end
