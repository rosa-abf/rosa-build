json.project do
  json.partial! 'project', project: @project
  json.partial! 'api/v1/shared/owner', owner: @project.owner
end
