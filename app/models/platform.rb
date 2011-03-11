class Platform < ActiveRecord::Base
  has_many :projects, :dependent => :destroy
  has_one :parent, :class_name => 'Platform', :foreign_key => 'parent_platform_id'

  validate :name, :presence => true, :uniqueness => true
  validate :unixname, :uniqueness => true, :presence => true, :format => { :with => /^[a-zA-Z0-9\-.]+$/ }, :allow_nil => false, :allow_blank => false

  before_create :create_directory

  def path
    build_path(unixname)
  end

  protected

    def build_path(dir)
      File.join(APP_CONFIG['root_path'], dir)
    end

    def create_directory
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} already exists" if exists
      if new_record?
        FileUtils.mkdir_p(path)
      elsif unixname_changed?
        FileUtils.mv(build_path(unixname_was), buildpath(unixname))
      end 
    end
end
