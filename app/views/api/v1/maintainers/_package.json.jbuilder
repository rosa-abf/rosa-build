json.(package, :id, :name, :version, :release, :epoch)
json.type package.package_type
json.updated_at package.updated_at.to_i
json.url (package.sha1 ? "#{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{package.sha1}" : '' )

json.dependent_projects dependent_projects(package) do |project, packages|
  json.partial! 'api/v1/projects/project', project: project
  json.dependent_packages packages
end if package.build_list.save_to_platform.main?