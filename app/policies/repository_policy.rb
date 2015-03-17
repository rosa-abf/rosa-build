class RepositoryPolicy < ApplicationPolicy

  def update?
    local_admin?(record.platform)
  end

  def reader?
    local_reader?(record.platform)
  end

  def write?
    local_writer?(record.platform)
  end

  def update?
    local_admin?(record.platform)
  end
  alias_method :manage_members?, :update?
  alias_method :remove_members?, :update?
  alias_method :add_member?, :update?

  def add_project?
    local_admin?(record.platform) || is_member_of_repository?
  end
  alias_method :remove_project?, :add_project?

private

  def is_member_of_repository?
    Rails.cache.fetch(['RepositoryPolicy#is_member_of_repository?', record, user]) do
      record.members.exists?(id: user.id)
    end
  end

end
