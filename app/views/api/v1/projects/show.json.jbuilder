json.project do
  json.partial! 'project', :project => @project
  json.(@project, :visibility, :description, :ancestry, :has_issues, :has_wiki, :default_branch, :is_package, :publish_i686_into_x86_64)
  json.created_at @project.created_at.to_i
  json.updated_at @project.updated_at.to_i
  json.partial! 'api/v1/shared/owner', :owner => @project.owner
  json.maintainer do
    json.partial! 'api/v1/shared/member', :member => @project.maintainer
  end

  json.project_statistics @project.project_statistics do |statistic|
    json.(statistic, :average_build_time, :build_count, :arch_id)
  end

  json.repositories @project.repositories do |repo|
    json.(repo, :id, :name)
    json.url api_v1_repository_path(repo.name, :format => :json)
    json.platform do
      json.(repo.platform, :id, :name)
      json.url api_v1_platform_path(repo.platform, :format => :json)
    end
  end
end