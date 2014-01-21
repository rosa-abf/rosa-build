class PlatformArchSetting < ActiveRecord::Base
  DEFAULT_TIME_LIVING = 43200   # seconds, 12 hours
  MIN_TIME_LIVING     = 600     # seconds, 10 minutes
  MAX_TIME_LIVING     = 360000  # seconds, 100 hours, 4 day and 4 hours
  include Modules::Models::TimeLiving

  belongs_to :arch
  belongs_to :platform

  validates :arch_id, :platform_id, presence: true
  validates :platform_id, :uniqueness   => {scope: :arch_id}

  scope :by_arch,     lambda {|arch| where(arch_id: arch) if arch.present?}
  scope :by_default,  where(default: true)

  attr_accessible :arch_id, :platform_id, :default

end
