json.array!(collaborators) do |collaborator|
  json.partial! 'projects/collaborators/collaborator', collaborator: collaborator
end
