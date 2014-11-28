json.array!(@users) do |user|
  json.(user, :id, :fullname)
  json.avatar_path avatar_url(user)
  json.path        user_path(user)
end
