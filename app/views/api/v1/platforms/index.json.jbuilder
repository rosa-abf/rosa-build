json.platforms @platforms do |platform|
  json.partial! 'platform', platform: platform
  json.partial! 'api/v1/shared/owner', owner: platform.owner
  json.repositories platform.repositories do |repo|
    json.(repo, :id, :name)
    json.url api_v1_repository_path(repo.id, format: :json)
  end
end

json.url api_v1_platforms_path(format: :json)
