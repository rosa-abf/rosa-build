class Arch < ActiveRecord::Base
  validate :name, :presence => true, :uniqueness => true
end
