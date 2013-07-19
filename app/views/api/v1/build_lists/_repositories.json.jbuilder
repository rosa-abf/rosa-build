json.partial! 'api/v1/repositories/repository', :repository => repository

json.platform do
  json.partial! 'api/v1/platforms/platform', :platform => repository.platform
end