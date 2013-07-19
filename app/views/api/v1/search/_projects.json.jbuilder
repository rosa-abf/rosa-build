json.projects results do |project|
  json.partial! 'api/v1/projects/project', :project => project
end