class Product < ActiveRecord::Base
  include TimeLiving
  include Autostart
  include EventLoggable

  belongs_to :platform
  belongs_to :project
  has_many :product_build_lists, dependent: :destroy

  validates :name, presence: true,
            uniqueness: { scope: :platform_id },
            length: { maximum: 100 }

  validates :project, presence: true
  validates :main_script, :params, length: { maximum: 255 }

  scope :recent, -> { order(:name) }

  attr_readonly :platform_id

  def full_clone(attrs = {})
    dup.tap do |c|
      attrs.each {|k,v| c.send("#{k}=", v)}
      c.time_living = c.time_living.to_i / 60 # see: TimeLiving#convert_time_living
      c.platform_id = nil
      c.product_build_lists = []
      c.updated_at = nil; c.created_at = nil
    end
  end

  class << self
    Autostart::HUMAN_AUTOSTART_STATUSES.each do |autostart_status, human_autostart_status|
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
