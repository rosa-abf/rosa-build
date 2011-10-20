class Role < ActiveRecord::Base
  has_many :permissions
  has_many :relations, :through => :role_lines
end
