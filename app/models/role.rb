class Role < ActiveRecord::Base
  has_many :permissions
  has_many :rights, :through => :permissions
  has_many :relations, :through => :role_lines

  serialize :can_see, Hash

  validate :name, :presence => true
end
