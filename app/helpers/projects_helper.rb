# -*- encoding : utf-8 -*-
module ProjectsHelper
  def git_repo_url(name)
    if current_user
      "https://#{current_user.uname}@#{request.host_with_port}/#{name}.git"
    else
      "https://#{request.host_with_port}/#{name}.git"
    end
  end

  def options_for_collaborators_roles_select
    options_for_select(
      Relation::ROLES.collect { |role|
        [t("layout.collaborators.role_names.#{ role }"), role]
      }
    )
  end

  def visibility_icon(visibility)
    visibility == 'open' ? 'unlock.png' : 'lock.png'
  end

  def participant_class(alone_member, project)
    c = alone_member ? 'user' : 'group'
    c = 'user_owner' if project.owner == current_user
    c = 'group_owner' if project.owner.in? current_user.groups
    return c
  end

  def alone_member?(project)
    Relation.by_target(project).by_object(current_user).size > 0
  end
end
