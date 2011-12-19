class Issue < ActiveRecord::Base
  STATUSES = ['open', 'close']

  extend FriendlyId
  friendly_id :serial_id

  belongs_to :project
  belongs_to :user

  has_many :comments, :as => :commentable

  validates :title, :body, :project_id, :user_id, :presence => true

  attr_readonly :serial_id

  after_create :set_serial_id

  protected

  def set_serial_id
    serial_id = project.issues.count + 1
    save
  end
end
