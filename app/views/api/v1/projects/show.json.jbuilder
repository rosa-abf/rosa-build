json.project do |json|
  json.(@project, :id, :name, :visibility, :description, :ancestry, :has_issues, :has_wiki, :default_branch, :is_package, :average_build_time)
  json.created_at @project.created_at.to_i
  json.updated_at @project.updated_at.to_i
  json.partial! 'api/v1/shared/owner', :owner => @project.owner
  json.maintainer do |json_maintainer|
    json_maintainer.(@project.maintainer, :id, :name)
    json_maintainer.type 'User'
    json_maintainer.url api_v1_user_path(@project.maintainer_id, :format => :json)
  end
  json.repositories @project.repositories do |json_repos, repo|
    json_repos.(repo, :id, :name)
    json_repos.url api_v1_repository_path(repo.name, :format => :json)
    json_repos.platform do |json_platform|
      json_platform.(repo.platform, :id, :name)
      json_platform.url api_v1_platform_path(repo.platform, :format => :json)
    end
  end
  json.url api_v1_project_path(@project.id, :format => :json)
end