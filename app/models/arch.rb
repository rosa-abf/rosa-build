class Arch < ActiveRecord::Base
  DEFAULT = %w[i586 x86_64]

  has_many :build_lists, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  scope :recent, order("#{table_name}.name ASC")
end
