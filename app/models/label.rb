class Label < ActiveRecord::Base
  has_many :labelings
  has_many :issues, :through => :labelings

  validates :name, :color, :presence => true
  validates :color, :format => { :with => /\A([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, :message => I18n.t('layout.issues.invalid_labels')}
end
