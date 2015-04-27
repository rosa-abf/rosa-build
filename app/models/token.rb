class Token < ActiveRecord::Base
  belongs_to :subject, polymorphic: true, touch: true
  belongs_to :creator, class_name: 'User'
  belongs_to :updater, class_name: 'User'

  validates :creator_id, :subject_id, :subject_type, presence: true
  validates :authentication_token, presence: true, uniqueness: { case_sensitive: true }
  validates :description, length: { maximum: 1000 }

  default_scope { order(created_at: :desc) }
  scope :by_active, -> { where(status: 'active') }

  before_validation :generate_token, on: :create

  # attr_accessible :description

  state_machine :status, initial: :active do
    event :block do
      transition [:active, :blocked] => :blocked
    end
  end

  protected

  def generate_token
    self.authentication_token = loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless Token.where(authentication_token: token).exists?
    end
  end

end
