class UserEmail < ActiveRecord::Base
  MAX_EMAILS = 10

  belongs_to :user

  validates :email_lower, :uniqueness => true
  validates :email, :presence => true

  before_save :set_lower
  before_validation :set_lower

  private

  def set_lower
    self.email_lower = self.email.downcase
  end
end
