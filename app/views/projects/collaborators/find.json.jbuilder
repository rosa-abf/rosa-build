json.array!(@collaborators) do |collaborator|
  json.(collaborator, :actor_uname, :actor_id, :actor_type)
end