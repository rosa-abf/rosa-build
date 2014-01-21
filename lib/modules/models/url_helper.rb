module Modules::Models::UrlHelper
  def default_url_options
    host ||= EventLog.current_controller.request.host_with_port rescue ::Rosa::Application.config.action_mailer.default_url_options[:host]
    protocol ||= APP_CONFIG['mailer_https_url'] ? 'https' : 'http' rescue 'http'
    {host: host, protocol: protocol}
  end
end
