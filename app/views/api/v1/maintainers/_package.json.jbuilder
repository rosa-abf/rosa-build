json.(package, :id, :name, :version, :release, :epoch)
json.type package.package_type
json.updated_at package.updated_at.to_i
json.url (package.sha1 ? "#{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{package.sha1}" : '' )