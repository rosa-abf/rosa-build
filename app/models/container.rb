class Container < ActiveRecord::Base
  belongs_to :project
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_id'

  validates :name, :presence => true
  validates :project_id, :presence => true
  validates :onwer_id, :presence => true
end
