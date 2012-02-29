# -*- encoding : utf-8 -*-
require 'xmlrpc/client'

class ProductBuilder
  SUCCESS = 0
  ERROR = 1

  def self.client(distrib_type)
    @@client ||= XMLRPC::Client.new3(:host => APP_CONFIG['product_builder_ip'][distrib_type], :port => APP_CONFIG['product_builder_port'], :path => APP_CONFIG['product_builder_path'])
  end

  def self.create_product pbl # product_build_list
    self.client(pbl.product.platform.distrib_type).
    call('create_product', pbl.id.to_s, pbl.product.platform.name, pbl.product.ks, pbl.product.menu, pbl.product.build_script,
                           pbl.product.counter, [], pbl.product.tar.exists? ? "#{pbl.base_url}#{pbl.product.tar.url}" : '')
  end
  
  def self.delete_iso_container(plname, id):
    self.client(pbl.product.platform.distrib_type).call('delete_iso_container', plname, id)
  end
end
