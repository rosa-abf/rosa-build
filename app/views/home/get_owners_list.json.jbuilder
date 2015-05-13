json.array!(@owners) do |owner|
  json.avatar_path avatar_url(owner)
  json.uname       owner.uname
end