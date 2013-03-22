# -*- encoding : utf-8 -*-
class Product < ActiveRecord::Base
  include Modules::Models::TimeLiving

  belongs_to :platform
  belongs_to :project
  has_many :product_build_lists, :dependent => :destroy

  ONCE_A_12_HOURS = 0
  ONCE_A_DAY      = 1
  ONCE_A_WEEK     = 2

  AUTOSTART_STATUSES        = [ONCE_A_12_HOURS, ONCE_A_DAY, ONCE_A_WEEK]
  HUMAN_AUTOSTART_STATUSES  = {
    ONCE_A_12_HOURS => :once_a_12_hours,
    ONCE_A_DAY      => :once_a_day,
    ONCE_A_WEEK     => :once_a_week
  }

  validates :name, :presence => true, :uniqueness => {:scope => :platform_id}
  validates :project_id, :presence => true
  validates :main_script, :params, :length => { :maximum => 255 }
  validates :autostart, :numericality => true, :inclusion => {:in => AUTOSTART_STATUSES}, :allow_blank => true

  scope :recent, order("#{table_name}.name ASC")

  attr_accessible :name,
                  :description,
                  :project_id,
                  :main_script,
                  :params,
                  :platform_id,
                  :autostart
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

  def human_status
    self.class.human_status(status)
  end

  def self.human_status(status)
    I18n.t("layout.products.autostart_statuses.#{HUMAN_AUTOSTART_STATUSES[status]}")
  end

end
