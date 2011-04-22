require 'xmlrpc/client'
class ProductBuilder

  SUCCESS = 0
  ERROR = 1
  

  def self.client
    @@client ||= XMLRPC::Client.new3(:host => APP_CONFIG['product_builder_ip'], :port => APP_CONFIG['product_builder_port'], :path => APP_CONFIG['product_builder_path'])
  end

  def self.create_product name, platform_name, params, packages, post_install, path, repos
    RAILS_DEFAULT_LOGGER.fatal @@client.port
    RAILS_DEFAULT_LOGGER.fatal @@client.inspect
    self.client.call('create_product', name, platform_name, params, packages, post_install, path, repos)
  end
end
