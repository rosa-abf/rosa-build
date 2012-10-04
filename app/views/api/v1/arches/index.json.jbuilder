json.architectures @arches do |json, arch|
  json.(arch, :id, :name)
end