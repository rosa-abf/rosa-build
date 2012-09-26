# -*- encoding : utf-8 -*-
class ProductBuildList < ActiveRecord::Base
  BUILD_STARTED = 2
  BUILD_COMPLETED = 0
  BUILD_FAILED = 1

  STATUSES = [  BUILD_STARTED,
                BUILD_COMPLETED,
                BUILD_FAILED
              ]

  HUMAN_STATUSES = { BUILD_STARTED => :build_started,
                     BUILD_COMPLETED => :build_completed,
                     BUILD_FAILED => :build_failed
                    }

  belongs_to :product

  validates :product_id, :status, :presence => true
  validates :status, :inclusion => { :in => [BUILD_STARTED, BUILD_COMPLETED, BUILD_FAILED] }

  attr_accessor :base_url
  attr_accessible :status, :base_url
  attr_readonly :product_id


  scope :default_order, order('updated_at DESC')
  scope :for_status, lambda {|status| where(:status => status) }
  scope :for_user, lambda { |user| where(:user_id => user.id)  }
  scope :scoped_to_product_name, lambda {|product_name| joins(:product).where('products.name LIKE ?', "%#{product_name}%")}
  scope :recent, order("#{table_name}.updated_at DESC")

  after_create :xml_rpc_create
  before_destroy :can_destroy?
  after_destroy :xml_delete_iso_container

  def container_path
    "/downloads/#{product.platform.name}/product/#{id}/"
  end

  def event_log_message
    {:product => product.name}.inspect
  end

  def self.human_status(status)
    I18n.t("layout.product_build_lists.statuses.#{HUMAN_STATUSES[status]}")
  end

  def human_status
    self.class.human_status(status)
  end

  def can_destroy?
    [BUILD_COMPLETED, BUILD_FAILED].include? status
  end

  protected

  def xml_rpc_create
    result = ProductBuilder.create_product self
    if result == ProductBuilder::SUCCESS
      return true
    else
      raise "Failed to create product_build_list #{id} inside platform #{product.platform.name} tar url #{tar_url} with code #{result}."
    end
  end  

  def xml_delete_iso_container
    result = ProductBuilder.delete_iso_container self
    if result == ProductBuilder::SUCCESS
      return true
    else
      raise "Failed to destroy product_build_list #{id} inside platform #{product.platform.name} with code #{result}."
    end
  end
end
