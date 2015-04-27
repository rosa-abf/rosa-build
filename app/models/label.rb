class Label < ActiveRecord::Base
  has_many :labelings, dependent: :destroy
  has_many :issues, through: :labelings
  belongs_to :project

  validates :name, uniqueness: { scope: :project_id }
  validates :name, length: { in: 1..20 }

  validates :color, presence: true
  validates :color, format: { with: /\A([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, message: I18n.t('layout.issues.invalid_labels') }

  # attr_accessible :name, :color
end
