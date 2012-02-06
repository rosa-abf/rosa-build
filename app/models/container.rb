# -*- encoding : utf-8 -*-
class Container < ActiveRecord::Base
  belongs_to :project
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_id'

  validates :name, :project_id, :onwer_id, :presence => true
end
