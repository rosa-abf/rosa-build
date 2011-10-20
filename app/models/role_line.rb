class RoleLine < ActiveRecord::Base
  belongs_to :role
  belongs_to :relation
end
