json.project do |proj|
  proj.visibility  project.visibility.to_s

  proj.name        project.name
  proj.description project.description
  proj.link        project_path(project)

  proj.role        t("layout.collaborators.role_names.#{project.relations.by_user_through_groups(current_user).first.role}").force_encoding(Encoding::UTF_8)

  proj.leave_link  remove_user_project_path(project) unless project.owner == current_user or project.owner.class == Group

  proj.owner do |owner|
    owner.name project.owner.uname
    owner.type project.owner.class.to_s.underscore
    owner.link project.owner.class == User ? user_path(project.owner) : group_path(project.owner)
  end
end
