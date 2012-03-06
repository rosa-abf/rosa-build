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
end
