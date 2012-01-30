class UserEmail < ActiveRecord::Base
  belongs_to :user

  validates :email, :uniqueness => true
  validates :email, :presence => true

end
