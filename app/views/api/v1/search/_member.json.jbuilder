json.(member, :id, :uname)
json.(member, :name) if member.is_a?(User)
json.url member_path(member)