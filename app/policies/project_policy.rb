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
    !user.guest? && (!record.try(:owner) || policy(record.owner).write?)
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

  def run_mass_import?
    return false unless policy(record.owner).write?
    repo = Repository.find(record.add_to_repository_id)
    repo.platform.main? && policy(repo.platform).add_project?
  end

  # for grack
  def write?
    local_writer?
  end

  def possible_forks
    true
  end

  class Scope < Scope

    def membered
      policy = Pundit.policy!(user, :project)
      scope.where <<-SQL, { user_id: user.id, user_group_ids: policy.user_group_ids }
        (
          projects.owner_type = 'User'  AND projects.owner_id = :user_id
        ) OR (
          projects.owner_type = 'Group' AND projects.owner_id IN (:user_group_ids)
        ) OR (
          projects.id = ANY (
            ARRAY (
              SELECT target_id
              FROM relations
              INNER JOIN projects ON projects.id = relations.target_id
              WHERE relations.target_type = 'Project' AND
              (
                projects.owner_type = 'User' AND projects.owner_id != :user_id OR
                projects.owner_type = 'Group' AND projects.owner_id NOT IN (:user_group_ids)
              ) AND (
                relations.actor_type = 'User' AND relations.actor_id = :user_id OR
                relations.actor_type = 'Group' AND relations.actor_id IN (:user_group_ids)
              )
            )
          )
        )
      SQL
    end
  end

end
