class RegisterRequest < ActiveRecord::Base

  default_scope order('created_at ASC')

  scope :rejected, where(rejected: true)
  scope :approved, where(approved: true)
  scope :unprocessed, where(approved: false, rejected: false)

  validates :email, presence: true, uniqueness: {case_sensitive: false}, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }

  # before_create :generate_token
  before_update :invite_approve_notification

  def approve
    update_attributes(approved: true, rejected: false)
  end

  def reject
    update_attributes(approved: false, rejected: true)
  end

  protected

  def generate_token
    self.token = Digest::SHA1.hexdigest(name + email + Time.now.to_s + rand.to_s)
  end

  def invite_approve_notification
    if approved_changed? && approved?
      generate_token
      UserMailer.invite_approve_notification(self).deliver
    end
  end
end
