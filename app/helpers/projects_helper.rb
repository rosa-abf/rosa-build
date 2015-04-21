module ProjectsHelper
  def options_for_filters(all_projects, groups, owners)
    projects_count_by_groups = all_projects.where(owner_id: groups, owner_type: 'Group').
      group(:owner_id).count
    projects_count_by_owners = all_projects.where(owner_id: owners, owner_type: 'User').
      group(:owner_id).count
    (groups + owners).map do |o|
      class_name = o.class.name
      {
        class_name: class_name.downcase,
        id: o.id,
        uname: o.uname,
        count: o.is_a?(User) ? projects_count_by_owners[o.id] : projects_count_by_groups[o.id]
      }
    end.sort_by{ |f| f[:uname] }
  end

  def available_project_to_repositories(project)
    project.project_to_repositories.includes(repository: :platform).select do |p_to_r|
      p_to_r.repository.publish_without_qa ? true : policy(p_to_r.repository.platform).local_admin_manage?
    end.sort_by do |p_to_r|
      "#{p_to_r.repository.platform.name}/#{p_to_r.repository.name}"
    end.map do |p_to_r|
      {
        repository_name:  "#{p_to_r.repository.platform.name}/#{p_to_r.repository.name}",
        repository_path:  platform_repository_path(p_to_r.repository.platform, p_to_r.repository),
        auto_publish:     p_to_r.auto_publish?,
        enabled:          p_to_r.enabled?,
        repository_id:    p_to_r.repository_id
      }
    end.to_a.to_json
  end

  def mass_import_repositories_for_group_select
    groups = {}
    PlatformPolicy::Scope.new(current_user, Platform).related.order(:name).each do |platform|
      next unless policy(platform).local_admin_manage?
      groups[platform.name] = Repository.custom_sort(platform.repositories).map{ |r| [r.name, r.id] }
    end
    groups.to_a
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
    Relation::ROLES.map do |role|
      [t("layout.collaborators.role_names.#{ role }"), role]
    end
  end

  def visibility_icon(visibility)
    visibility == 'open' ? 'unlock.png' : 'lock.png'
  end

  def participant_class(alone_member, project)
    c = alone_member ? 'fa-user text-primary' : 'fa-group text-primary'
    c = 'fa-user text-success' if project.owner == current_user
    c = 'fa-group text-success' if project.owner.in? current_user.groups
    return c
  end

  def alone_member?(project)
    Rails.cache.fetch(['ProjectsHelper#alone_member?', project, current_user]) do
      Relation.by_target(project).by_actor(current_user).exists?
    end
  end

  def participant_path(participant)
    participant.kind_of?(User) ? user_path(participant) : group_path(participant)
  end

  def fa_visibility_icon(project)
    return nil unless project
    image, color = project.public? ? ['unlock-alt', 'text-success fa-fw'] : ['lock', 'text-danger fa-fw']
    fa_icon(image, class: color)
  end

  def project_ownership_options
    [
      [ I18n.t('activerecord.attributes.project.who_owns.me'), 'me' ],
      [ I18n.t('activerecord.attributes.project.who_owns.group'), 'group' ]
    ]
  end

  def project_visibility_options
    Project::VISIBILITIES.map do |v|
      [ I18n.t("activerecord.attributes.project.visibilities.#{v}"), v ]
    end
  end

  def project_owner_groups_options
    Group.can_own_project(current_user).map do |g|
      [ g.name, g.id ]
    end
  end
end
