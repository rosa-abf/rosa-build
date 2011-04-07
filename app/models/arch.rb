class Arch < ActiveRecord::Base
  has_many :build_lists, :dependent => :destroy

  validates :name, :presence => true, :uniqueness => true

  scope :recent, order("name ASC")
end
