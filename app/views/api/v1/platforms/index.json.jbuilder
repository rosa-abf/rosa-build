json.platforms @platforms do |json, platform|
  json.(platform, :id, :name, :platform_type, :visibility)
  json.owner do |json_owner|
    json_owner.(platform.owner, :id, :name)
    json_owner.type platform.owner_type
    json_owner.url platform.owner_type == 'User' ? user_path(platform.owner) : group_path(platform.owner)
  end
  json.url api_v1_platform_path(platform.name, :format => :json)
end

json.url api_v1_platforms_path(:format => :json)
