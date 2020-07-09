module FileStoreHelper

  def file_store_results_url(sha1, file_name)
    url = "#{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{sha1}"
    url << '.log?show=true' if file_name =~ /.*\.(log|txt)$/ || file_name =~ /.*\.(log.gz|txt.gz)/
    url
  end

  def link_to_file_store(file_name, sha1)
    if sha1.present?
      link_to file_name, file_store_results_url(sha1, file_name)
    else
      I18n.t('layout.no_')
    end
  end

end
