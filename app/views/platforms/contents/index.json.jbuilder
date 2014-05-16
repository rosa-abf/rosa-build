json.contents (@contents.select(&:is_folder?) | @contents) do |content|
  json.(content, :name)
  json.is_folder content.is_folder?

  path =
    if content.is_folder?
      content.subpath
    else
      content.download_url
    end
  json.path path

  json.build_list do
    json.url build_list_path(content.build_list)
  end if content.build_list
end

json.path  @path
json.pages angularjs_will_paginate(@contents)
