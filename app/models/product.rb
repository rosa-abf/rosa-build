class Product < ActiveRecord::Base
  include Modules::Models::TimeLiving

  belongs_to :platform
  belongs_to :project
  has_many :product_build_lists, dependent: :destroy

  ONCE_A_12_HOURS = 0
  ONCE_A_DAY      = 1
  ONCE_A_WEEK     = 2

  AUTOSTART_STATUSES        = [ONCE_A_12_HOURS, ONCE_A_DAY, ONCE_A_WEEK]
  HUMAN_AUTOSTART_STATUSES  = {
    ONCE_A_12_HOURS => :once_a_12_hours,
    ONCE_A_DAY      => :once_a_day,
    ONCE_A_WEEK     => :once_a_week
  }

  validates :name, presence: true, uniqueness: {scope: :platform_id}
  validates :project_id, presence: true
  validates :main_script, :params, length: { maximum: 255 }
  validates :autostart_status, numericality: true,
    inclusion: {in: AUTOSTART_STATUSES}, allow_blank: true

  scope :recent, order("#{table_name}.name ASC")

  attr_accessible :name,
                  :description,
                  :project_id,
                  :main_script,
                  :params,
                  :platform_id,
                  :autostart_status,
                  :project_version
  attr_readonly :platform_id

  def full_clone(attrs = {})
    dup.tap do |c|
      attrs.each {|k,v| c.send("#{k}=", v)}
      c.time_living = c.time_living.to_i / 60 # see: Modules::Models::TimeLiving#convert_time_living
      c.platform_id = nil
      c.product_build_lists = []
      c.updated_at = nil; c.created_at = nil
    end
  end

  def human_autostart_status
    self.class.human_autostart_status(autostart_status)
  end

  def self.human_autostart_status(autostart_status)
    I18n.t("layout.products.autostart_statuses.#{HUMAN_AUTOSTART_STATUSES[autostart_status]}")
  end

  class << self
    HUMAN_AUTOSTART_STATUSES.each do |autostart_status, human_autostart_status|
      define_method "autostart_iso_builds_#{human_autostart_status}" do
        autostart_iso_builds autostart_status
      end
    end
  end

  def self.autostart_iso_builds(autostart_status)
    Product.where(autostart_status: autostart_status).each do |product|
      pbl = product.product_build_lists.new
      [:params, :main_script, :project, :project_version].each do |k|
        pbl.send "#{k}=", product.send(k)
      end
      owner = product.platform.owner
      pbl.user            = owner.is_a?(User) ? owner : owner.owner
      pbl.autostarted     = true
      pbl.base_url        = "http://#{product.platform.default_host}"
      pbl.time_living     = product.time_living / 60
      pbl.save
    end
  end

end
