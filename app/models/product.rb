class Product < ActiveRecord::Base
  NEVER_BUILT = 2
  BUILD_COMPLETED = 0
  BUILD_FAILED = 1

  validates :name, :presence => true, :uniqueness => true
  validates :platform_id, :presence => true
  validates :build_status, :inclusion => { :in => [ NEVER_BUILT, BUILD_COMPLETED, BUILD_FAILED ] }

  belongs_to :platform

  scope :recent, order("name ASC")
end
