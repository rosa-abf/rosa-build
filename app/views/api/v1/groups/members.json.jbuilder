json.group do
  json.(@group, :id)
  json.partial! 'api/v1/shared/members'
end
json.url members_api_v1_group_path(@group.id, :format => :json)