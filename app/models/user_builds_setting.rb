class UserBuildsSetting < ActiveRecord::Base
  include ExternalNodable

  belongs_to :user

  validates :user, presence: true

end
