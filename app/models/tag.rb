class Tag < ActiveRecord::Base
  belongs_to :issue

  validates :name, :color, :presence => true
  validates :color, :format => { :with => /\A([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, :message => I18n.t('layout.issues.invalid_labels')}

  before_create {|t| t.project_id = t.issue.project_id}
end
