require 'xmlrpc/client'

class ProductBuilder
  SUCCESS = 0
  ERROR = 1

  def self.client(distrib_type)
    @@client ||= XMLRPC::Client.new3(:host => APP_CONFIG['product_builder_ip'][distrib_type], :port => APP_CONFIG['product_builder_port'], :path => APP_CONFIG['product_builder_path'])
  end

  def self.create_product product, base_url
    self.client(product.platform.distrib_type).
    call('create_product', product.id.to_s, product.platform.unixname, product.ks, product.menu,
                           product.build_script, product.counter, [], "#{base_url}#{product.tar.url}")
  end
end
