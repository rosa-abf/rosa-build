json.array!(collaborators) do |collaborator|
  json.partial! 'collaborator.json', collaborator: collaborator
end
