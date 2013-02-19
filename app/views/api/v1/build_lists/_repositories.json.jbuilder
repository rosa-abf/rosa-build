json.partial! 'api/v1/repositories/repository',
    :repository => repository,
    :json => json

json.platform do |json_str_platform|
  json.partial! 'api/v1/platforms/platform',
      :platform => repository.platform,
      :json => json
end