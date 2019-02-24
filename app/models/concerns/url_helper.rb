module UrlHelper
  def default_url_options
    host ||= EventLog.current_controller.request.host_with_port rescue APP_CONFIG['abf_host']
    protocol ||= APP_CONFIG['mailer_https_url'] ? 'https' : 'http' rescue 'http'
    { host: host, protocol: protocol }
  end
end
