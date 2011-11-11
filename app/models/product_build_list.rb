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
    {:product => Product.find(product_id).name}.inspect # TODO WTF product.name == nil ???
  end

  protected

  def xml_rpc_create
    tar_url = "#{base_url}#{product.tar.url}"
    result = ProductBuilder.create_product id, product.platform.unixname, product.ks, product.menu, product.build, product.counter, [], tar_url
    if result == ProductBuilder::SUCCESS
      return true
    else
      # return false
      raise "Failed to create product_build_list #{id} inside platform #{product.platform.unixname} tar url #{tar_url} with code #{result}."
    end
  end
end
