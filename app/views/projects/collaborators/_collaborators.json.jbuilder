json.array!(collaborators) do |cb|
  json.(cb, :id, :actor_id, :actor_name, :actor_type, :project_id)
  json.collaborator do # attr_accessible for AngularJS
    json.(cb, :role)
  end
  json.project do
    json.(cb.project, :name, :owner_uname)
  end
  json.avatar            avatar_url(cb.actor)
  json.actor_path        participant_path(cb.actor)

end
