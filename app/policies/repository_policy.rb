class RepositoryPolicy < ApplicationPolicy

  def show?
    is_admin? || PlatformPolicy.new(user, record.platform).show?
  end
  alias_method :projects?,      :show?
  alias_method :projects_list?, :show?
  alias_method :read?,          :show?

  def reader?
    is_admin? || local_reader?(record.platform)
  end

  def write?
    is_admin? || local_writer?(record.platform)
  end

  def update?
    is_admin? || local_admin?(record.platform)
  end
  alias_method :manage_members?,        :update?
  alias_method :regenerate_metadata?,   :update?
  alias_method :signatures?,            :update?

  def create?
    return false if record.platform.personal? && record.name == 'main'
    is_admin? || owner?(record.platform) || local_admin?(record.platform)
  end
  alias_method :destroy?, :create?

  def packages?
    record.platform.main? && ( is_admin? || local_admin?(record.platform) )
  end
  alias_method :remove_member?,         :packages?
  alias_method :remove_members?,        :packages?
  alias_method :add_member?,            :packages?
  alias_method :sync_lock_file?,        :packages?

  def add_project?
    is_admin? || local_admin?(record.platform) || repository_user_ids.include?(user.id)
  end
  alias_method :remove_project?, :add_project?

  def settings?
    is_admin? || owner?(record.platform) || local_admin?(record.platform)
  end

  def key_pair?
    user.system?
  end

  def add_repo_lock_file?
    is_admin? || user.system? || ( record.platform.main? && local_admin?(record.platform) )
  end
  alias_method :remove_repo_lock_file?, :add_repo_lock_file?

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(
      name
      description
      publish_without_qa
      synchronizing_publications
      publish_builds_only_from_branch
      build_for_platform_id
    )
  end

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
