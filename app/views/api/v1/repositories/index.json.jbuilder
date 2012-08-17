json.repositories @repositories do |json, repository|
  json.(repository, :id, :name)
  json.platform do |json_platform|
    json_platform.(repository.platform, :id, :name)
    json_platform.url api_v1_platform_path(repository.platform)
  end
  json.url api_v1_repository_path(repository, :format => :json)
end

json.url api_v1_repositories_path(:format => :json)
