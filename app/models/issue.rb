class Issue < ActiveRecord::Base
  STATUSES = ['open', 'closed']

  belongs_to :project
  belongs_to :user

  has_many :comments, :as => :commentable

  validates :title, :body, :project_id, :user_id, :presence => true

  #attr_readonly :serial_id

  after_create :set_serial_id

  def to_param
    serial_id.to_s
  end

  protected

  def set_serial_id
    self.serial_id = self.project.issues.count
    self.save!
  end
end
