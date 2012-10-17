json.platforms @platforms do |json, platform|
  json.(platform, :id, :name, :platform_type, :visibility)
  json.partial! 'api/v1/shared/owner', :owner => platform.owner
  json.repositories platform.repositories do |json_repos, repo|
    json_repos.(repo, :id, :name)
    json_repos.url api_v1_repository_path(repo.id, :format => :json)
  end
  json.url api_v1_platform_path(platform.id, :format => :json)
end

json.url api_v1_platforms_path(:format => :json)
