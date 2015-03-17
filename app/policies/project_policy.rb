class ProjectPolicy < ApplicationPolicy

  def index?
    !user.guest?
  end

  def show?
    record.public? || local_reader?
  end
  alias_method :read?, :show?
  alias_method :fork?, :show?

  def create?
    !user.guest?
  end

  def update?
    local_admin?
  end
  alias_method :alias?, :update?

  def destroy?
    owner? || record.owner.is_a?(Group) && record.owner.actors.exists?(actor_type: 'User', actor_id: user.id, role: 'admin')
  end

  def mass_import?
    user.platforms.main.find{ |p| local_admin?(p) }.present?
  end
  alias_method :run_mass_import?, :mass_import?

  # for grack
  def write?
    local_writer?
  end

  def possible_forks
    true
  end

end
