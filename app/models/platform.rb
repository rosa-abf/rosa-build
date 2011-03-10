class Platform < ActiveRecord::Base
  has_many :projects, :dependent => :destroy
  has_one :parent, :class_name => 'Platform', :foreign_key => 'parent_platform_id'

  validate :name, :presence => true, :uniqueness => true
  validate :unixname, :uniqueness => true, :presence => true, :format => { :with => /^[a-zA-Z0-9\-.]+$/ }, :allow_nil => false, :allow_blank => false

  before_validation :generate_unixname

  protected

    def generate_unixname
      self.unixname = name.gsub(/[^a-zA-Z0-9\-.]/, '-')
      #TODO: Fix non-unique unixname
    end
end
