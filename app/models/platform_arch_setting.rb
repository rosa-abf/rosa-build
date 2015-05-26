class PlatformArchSetting < ActiveRecord::Base
  DEFAULT_TIME_LIVING = 43200   # seconds, 12 hours
  MIN_TIME_LIVING     = 600     # seconds, 10 minutes
  MAX_TIME_LIVING     = 360000  # seconds, 100 hours, 4 day and 4 hours
  include TimeLiving

  belongs_to :arch
  belongs_to :platform

  validates :arch, :platform, presence: true
  validates :platform_id, uniqueness: { scope: :arch_id }
  validate lambda {
    errors.add(:platform, I18n.t('flash.platform_arch_settings.wrong_platform')) unless platform.main?
  }

  scope :by_arch,    ->(arch) { where(arch_id: arch) if arch.present? }
  scope :by_default, -> { where(default: true) }
end
