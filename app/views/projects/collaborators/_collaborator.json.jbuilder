json.(collaborator, :id, :actor_name, :actor_type, :actor_id, :role)

json.avatar avatar_url(collaborator.actor)
json.path   participant_path(collaborator.actor)
