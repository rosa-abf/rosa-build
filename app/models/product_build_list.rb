class ProductBuildList < ActiveRecord::Base
  include CommitAndVersion
  include TimeLiving
  include FileStoreClean
  include UrlHelper
  include EventLoggable
  include ProductBuildLists::Statusable
  include ProductBuildLists::AbfWorkerable

  LIVE_TIME     = 2.week  # for autostart
  MAX_LIVE_TIME = 3.month # for manual start;

  belongs_to :product
  belongs_to :project
  belongs_to :arch
  belongs_to :user

  # see: Issue #6
  before_validation -> { self.arch_id = Arch.find_by(name: 'x86_64').id }, on: :create
  # field "not_delete" can be changed only if build has been completed
  before_validation -> { self.not_delete = false unless build_completed?; true }

  validates :product, :product_id,
            :project, :project_id,
            :main_script,
            :arch,    :arch_id,
            presence: true
  validates :main_script, :params, length: { maximum: 255 }

  attr_accessor :base_url, :product_name

  attr_readonly :product_id
  serialize :results, Array


  scope :default_order,           -> { order(updated_at: :desc) }
  scope :for_user,                -> (user) { where(user_id: user.id) }
  scope :scoped_to_product_name,  -> (product_name) {
    joins(:product).where('products.name LIKE ?', "%#{product_name}%") if product_name.present?
  }
  scope :recent,                  -> { order(updated_at: :desc) }
  scope :outdated, -> {
    where(not_delete: false).
    where("(#{table_name}.created_at < ? AND #{table_name}.autostarted is TRUE) OR #{table_name}.created_at < ?",
          Time.now - LIVE_TIME, Time.now - MAX_LIVE_TIME)
  }

  after_initialize :init_project, if: :new_record?

  def event_log_message
    {product: product.name}.inspect
  end

  protected

  def init_project
    self.project ||= product.try(:project)
  end

end
