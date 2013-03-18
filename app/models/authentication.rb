class Authentication < ActiveRecord::Base
  belongs_to :user

  validates :provider, :uid, :presence => true
  validates :uid, :uniqueness => {:scope => :provider, :case_sensitive => false}
end
