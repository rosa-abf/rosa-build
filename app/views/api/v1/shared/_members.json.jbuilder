json.members @members do |member|
  json.partial! 'api/v1/shared/member', :member => member
end