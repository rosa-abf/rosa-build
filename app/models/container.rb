class Container < ActiveRecord::Base
  validate :name, :presence => true
  validate :project_id, :presence => true
  validate :onwer_id, :presence => true

  belongs_to :project
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_id'
end
