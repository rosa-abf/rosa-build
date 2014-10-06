class Statistic < ActiveRecord::Base
  # TYPES = %w()

  belongs_to :user
  belongs_to :project

  validates :user_id,
    uniqueness: { scope: [:project_id, :type, :activity_at] },
    presence: true

  validates :email,
    presence: true

  validates :project_id, 
    presence: true

  validates :project_name_with_owner,
    presence: true

  validates :type,
    presence: true

  validates :counter,
    presence: true

  validates :activity_at,
    presence: true

  attr_accessible :user_id,
                  :email,
                  :project_id,
                  :project_name_with_owner,
                  :type,
                  :counter,
                  :activity_at
end
