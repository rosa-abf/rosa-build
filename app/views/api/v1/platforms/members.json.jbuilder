json.platform do |json|
  json.partial! 'platform', :platform => @platform, :json => json
  json.partial! 'api/v1/shared/members'
end
json.url members_api_v1_platform_path(@platform.id, :format => :json)