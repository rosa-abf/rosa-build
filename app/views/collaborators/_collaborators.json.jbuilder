json.array!(collaborators) do |json, cb|
  json.id                cb.id.to_s + '-' + cb.type
  json.name              cb.name
  json.collaborator_link participant_path(cb.actor)
  json.avatar            avatar_url(cb.actor) if cb.actor.kind_of?(User)
  json.type              cb.type
  json.project_id        cb.project_id
  json.role              cb.role
end
