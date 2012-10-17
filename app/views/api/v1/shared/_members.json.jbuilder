json.members @members do |json_members, member|
  json.partial! 'api/v1/shared/member', :member => member, :tag => json_members
end