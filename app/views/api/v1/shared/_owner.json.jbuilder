json.owner do |json_owner|
  json_owner.(owner, :id, :name)
  json_owner.type owner.class.name
  json_owner.url member_path(owner)
end