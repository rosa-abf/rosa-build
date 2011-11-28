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
      # return false
      raise "Failed to create product_build_list #{id} inside platform #{product.platform.name} tar url #{tar_url} with code #{result}."
    end
  end
end
