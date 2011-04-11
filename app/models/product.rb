class Product < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
  validates :platform_id, :presence => true
  validates :build_status, :inclusion => { :in => [ NEVER_BUILT, BUILD_COMPLETED, BUILD_FAILED ] }

  belongs_to :platform

  NEVER_BUILT = 2
  BUILD_COMPLETED = 0
  BUILD_FAILED = 1
end
