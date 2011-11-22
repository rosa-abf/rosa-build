require 'xmlrpc/client'

class ProductBuilder

  SUCCESS = 0
  ERROR = 1
  

  def self.client
    @@client ||= XMLRPC::Client.new3(:host => APP_CONFIG['product_builder_ip'], :port => APP_CONFIG['product_builder_port'], :path => APP_CONFIG['product_builder_path'])
  end

  def self.create_product product_id, path, kstemplate, menuxml, build, counter, packages, tar_url
    self.client.call('create_product', product_id.to_s, path, kstemplate, menuxml, build, counter, packages, tar_url)
  end
end
