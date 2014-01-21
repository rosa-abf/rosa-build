module ProjectsHelper
  def options_for_filters(all_projects, groups, owners)
    projects_count_by_groups = all_projects.where(owner_id: groups, owner_type: 'Group').
      group(:owner_id).count
    projects_count_by_owners = all_projects.where(owner_id: owners, owner_type: 'User').
      group(:owner_id).count
    (groups + owners).map do |o|
      class_name = o.class.name
      {
        id: "#{class_name.downcase}-#{o.id}",
        color: '0054a6',
        selected: false,
        check_box_name: class_name.downcase.pluralize,
        check_box_value: o.id,
        name: content_tag(:div, content_tag(:span, o.uname, class: class_name.downcase)),
        uname: o.uname, # only for sorting
        count: o.is_a?(User) ? projects_count_by_owners[o.id] : projects_count_by_groups[o.id]
      }
    end.sort_by{ |f| f[:uname] }
  end

  def repositories_grouped_by_platform
    groups = {}
    Platform.accessible_by(current_ability, :related).order(:name).each do |platform|
      next unless can?(:local_admin_manage, platform)
      groups[platform.name] = Repository.custom_sort(platform.repositories).map{ |r| [r.name, r.id] }
    end
    groups
  end

  def git_repo_url(name)
    if current_user
      "#{request.protocol}#{current_user.uname}@#{request.host_with_port}/#{name}.git"
    else
      "#{request.protocol}#{request.host_with_port}/#{name}.git"
    end
  end

  def git_ssh_repo_url(name)
    "git@#{request.host}:#{name}.git"
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
    Relation.by_target(project).by_actor(current_user).size > 0
  end

  def participant_path(participant)
    participant.kind_of?(User) ? user_path(participant) : group_path(participant)
  end
end
