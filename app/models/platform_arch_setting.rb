# -*- encoding : utf-8 -*-
class PlatformArchSetting < ActiveRecord::Base
  DEFAULT_TIME_LIVING = 43200   # seconds, 12 hours
  MIN_TIME_LIVING     = 600     # seconds, 10 minutes
  MAX_TIME_LIVING     = 172800  # seconds, 48 hours
  include Modules::Models::TimeLiving

  belongs_to :arch
  belongs_to :platform

  validates :arch_id, :platform_id, :presence => true
  validates :platform_id, :uniqueness   => {:scope => :arch_id}

  scope :by_arch, lambda {|arch| where(:arch_id => arch) if arch.present?}

  attr_accessible :arch_id, :platform_id, :default

end
