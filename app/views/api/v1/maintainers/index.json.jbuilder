json.maintainers @maintainers do |maintainer|
  json.project do
    json.partial! 'api/v1/projects/project', project: maintainer.project
  end

  json.package do
    json.partial! 'package', package: maintainer
  end

  json.maintainer do
    if user = maintainer.try(:assignee)
      json.partial! 'maintainer', maintainer: user
    end
  end
end
