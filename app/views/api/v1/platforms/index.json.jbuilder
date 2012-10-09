json.platforms @platforms do |json, platform|
  json.(platform, :id, :name, :platform_type, :visibility)
  json.owner do |json_owner|
    json_owner.(platform.owner, :id, :name)
    json_owner.type platform.owner_type
    json_owner.url url_for(platform.owner)
  end
  json.repositories platform.repositories do |json_repos, repo|
    json_repos.(repo, :id, :name)
    json_repos.url api_v1_repository_path(repo.name, :format => :json)
  end
  json.url api_v1_platform_path(platform.name, :format => :json)
end

json.url api_v1_platforms_path(:format => :json)
