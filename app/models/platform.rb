class Platform < ActiveRecord::Base
  has_many :projects, :dependent => :destroy
  has_one :parent, :class_name => 'Platform', :foreign_key => 'parent_platform_id'

  validate :name, :presence => true, :uniqueness => true
  validate :unixname, :presence => true, :uniqueness => true
  validate :validate_unixname

  before_validation :generate_unixname

  protected

    def generate_unixname
      #TODO: Implement unixname generation 
    end

    def validate_unixname
      #TODO: Implement unixname validation
    end
end
