json.group do |json|
  json.(@group, :id)
  json.members @members do |json_members, member|
    json_members.(member, :id)
    json_members.type member.class.name
    json_members.url member_path(member)
  end
end
json.url members_api_v1_group_path(@group.id, :format => :json)