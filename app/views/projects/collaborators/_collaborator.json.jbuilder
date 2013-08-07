json.(collaborator, :id, :actor_name)
json.collaborator do # attr_accessible for AngularJS
  json.(collaborator, :role, :actor_id, :actor_type, :project_id)
end
json.project do
  json.(collaborator.project, :name, :owner_uname)
end
json.avatar            avatar_url(collaborator.actor)
json.actor_path        participant_path(collaborator.actor)