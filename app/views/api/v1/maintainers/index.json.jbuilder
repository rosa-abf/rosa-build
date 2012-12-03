json.maintainers @maintainers do |json, maintainer|
  json.project do |json_project|
    json_project.partial! 'api/v1/projects/project', :project => maintainer.project, :json => json
  end

  json.package do |json_package|
    json_package.partial! 'package', :package => maintainer, :json => json
  end

  json.maintainer do |json_maintainer|
    if user = maintainer.try(:assignee)
      json_maintainer.partial! 'maintainer', :maintainer => user, :json => json
    end
  end
end
