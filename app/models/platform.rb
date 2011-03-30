class Platform < ActiveRecord::Base
  belongs_to :parent, :class_name => 'Platform', :foreign_key => 'parent_platform_id'
  has_many :repositories, :dependent => :destroy

  validates :name, :presence => true, :uniqueness => true
  validates :unixname, :uniqueness => true, :presence => true, :format => { :with => /^[a-zA-Z0-9\-.]+$/ }, :allow_nil => false, :allow_blank => false

  before_create :create_directory

  def path
    build_path(unixname)
  end

  def clone(new_name, new_unixname)
    p = Platform.new
    p.name = new_name
    p.unixname = new_unixname
    p.parent = self
    p.repositories = repositories.map(&:clone)
    p.save!
    return p
  end

  def name
    released? ? "#{self[:name]} #{I18n.t("layout.platforms.released_suffix")}" : self[:name]
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
