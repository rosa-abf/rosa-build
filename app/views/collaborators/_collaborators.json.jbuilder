json.array!(collaborators) do |json, cb|
  json.id                cb.id

  json.actor_id          cb.actor_id
  json.actor_name        cb.actor_name
  json.actor_type        cb.actor_type
  json.avatar            avatar_url(cb.actor)
  json.actor_path        participant_path(cb.actor)

  json.project_id        cb.project_id
  json.role              cb.role
end
