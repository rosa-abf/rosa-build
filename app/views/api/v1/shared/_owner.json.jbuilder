json.owner do |json_owner|
  json.partial! 'api/v1/shared/member', :member => owner, :tag => json_owner
end