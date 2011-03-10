class Project < ActiveRecord::Base
  belongs_to :platform

  validate :name, :uniqueness => true, :presence => true
  validate :unixname, :uniqueness => true, :presence => true
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
