class ProjectPolicy < ApplicationPolicy

  def index?
    !user.guest?
  end
  alias_method :autocomplete_project?,      :index?
  alias_method :remove_user?,               :index?
  alias_method :preview?,                   :index?

  def show?
    return true if is_admin?
    return true if record.public?
    return true if record.owner == user
    return true if record.owner.is_a?(Group) && user_group_ids.include?(record.owner_id)
    local_reader?
  end
  alias_method :read?,                      :show?
  alias_method :fork?,                      :show?
  alias_method :archive?,                   :show?
  alias_method :get_id?,                    :show?
  alias_method :refs_list?,                 :show?

  def create?
    return true if is_admin?
    return false if user.guest?
    owner_policy.write?
  end

  def update?
    is_admin? || owner? || local_admin?
  end
  alias_method :alias?,                     :update?
  alias_method :sections?,                  :update?
  alias_method :manage_collaborators?,      :update?
  alias_method :autocomplete_maintainers?,  :update?
  alias_method :add_member?,                :update?
  alias_method :remove_member?,             :update?
  alias_method :remove_members?,            :update?
  alias_method :update_member?,             :update?
  alias_method :members?,                   :update?
  alias_method :schedule?,                  :update?

  def destroy?
    is_admin? || owner? || record.owner.is_a?(Group) && record.owner.actors.exists?(actor_type: 'User', actor_id: user.id, role: 'admin')
  end

  def mass_import?
    is_admin? || user.platforms.main.find{ |p| local_admin?(p) }.present?
  end

  def run_mass_import?
    return true if is_admin?
    return false unless owner_policy.write?
    repo = Repository.find(record.add_to_repository_id)
    repo.platform.main? && PlatformPolicy.new(user, repo.platform).add_project?
  end

  # for grack
  def write?
    is_admin? || owner? || local_writer?
  end

  def possible_forks
    true
  end

  class Scope < Scope

    def membered
      scope.where <<-SQL, { user_id: policy.user.id, user_group_ids: policy.user_group_ids }
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

    def read
      scope.where <<-SQL, { user_id: policy.user.id, user_group_ids: policy.user_group_ids }
        (
          projects.visibility = 'open'
        ) OR (
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
    alias_method :show, :read

    protected

    def policy
      @policy ||= Pundit.policy!(user, :project)
    end
  end

  private

  def owner_policy
    if record.owner.is_a?(User)
      UserPolicy.new(user, record.owner)
    else
      GroupPolicy.new(user, record.owner)
    end
  end

end
