# -*- encoding : utf-8 -*-
class ProductBuildList < ActiveRecord::Base
  BUILD_STARTED = 2
  BUILD_COMPLETED = 0
  BUILD_FAILED = 1

  belongs_to :product

  validates :product, :status, :presence => true
  validates :status, :inclusion => { :in => [BUILD_STARTED, BUILD_COMPLETED, BUILD_FAILED] }

  scope :default_order, order('notified_at DESC')

  attr_accessor :base_url

  after_create :xml_rpc_create
  after_destroy :xml_delete_iso_container

  def container_path
    "/downloads/#{product.platform.name}/product/#{id}/"
  end

  def human_status
    I18n.t("layout.product_build_lists.statuses.#{status}")
  end

  def event_log_message
    {:product => product.name}.inspect
  end

  protected

  def xml_rpc_create
    result = ProductBuilder.create_product self
    if result == ProductBuilder::SUCCESS
      return true
    else
      raise "Failed to create product_build_list #{id} inside platform #{platform.name} tar url #{tar_url} with code #{result}."
    end
  end  
    
  def xml_delete_iso_container
    result = ProductBuilder.delete_iso_container self
    if result == ProductBuilder::SUCCESS
      return true
    else
      raise "Failed to destroy product_build_list #{id} inside platform #{platform.name} with code #{result}."
    end
  end
    
end
