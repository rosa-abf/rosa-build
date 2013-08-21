# -*- encoding : utf-8 -*-
module BuildsHelper

  def file_store_results_url(sha1, file_name)
    url = "#{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{sha1}"
    url << '.log?show=true' if file_name =~ /.*\.(log|txt)$/
    url
  end

end
