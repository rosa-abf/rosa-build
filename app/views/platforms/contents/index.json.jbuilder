json.contents (@contents.select(&:is_folder?) | @contents) do |content|
  json.(content, :name)
  json.is_folder content.is_folder?

  json.download_url content.download_url unless content.is_folder?
  json.subpath content.subpath

  json.build_list do
    json.url build_list_path(content.build_list)
  end if content.build_list
end

paths = @path.split('/').select(&:present?)
compound_path = ''
json.folders (['/'] | paths) do |folder|
  compound_path << '/' << folder if folder != '/'
  json.path compound_path.dup
  json.name folder
end

json.back paths.size == 1 ? '/' : paths[0...-1].join('/')

json.pages angularjs_will_paginate(@contents)
