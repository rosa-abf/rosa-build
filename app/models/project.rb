class Project < ActiveRecord::Base
  validate :name, :uniqueness => true, :presence => true
  validate :unixname, :uniqueness => true, :presence => true
  before_validation :generate_unixname
  validate :validate_unixname

  belongs_to :platform

  protected

    def generate_unixname
      #TODO: Implement unixname generation 
    end

    def validate_unixname
      #TODO: Implement unixname validation
    end

end
