class UserEmail < ActiveRecord::Base
  MAX_EMAILS = 10

  belongs_to :user

  validates :email, :uniqueness => true
  validates :email, :presence => true

end
