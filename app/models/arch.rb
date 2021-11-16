class Arch < ActiveRecord::Base
  DEFAULT = %w[i686 x86_64 aarch64]

  has_many :build_lists, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  scope :recent, -> { order(:name) }
end
