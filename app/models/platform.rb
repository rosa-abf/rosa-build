class Platform < ActiveRecord::Base
  validate :name, :presence => true, :uniqueness => true
  validate :unixname, :presence => true, :uniqueness => true
  before_validation :generate_unixname
  validate :validate_unixname

  has_many :projects
  has_one :parent, :class_name => 'Platform', :foreign_key => 'parent_platform_id'

  protected

    def generate_unixname
      #TODO: Implement unixname generation 
    end

    def validate_unixname
      #TODO: Implement unixname validation
    end
end
