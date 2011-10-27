class Group < ActiveRecord::Base
  relationable :as => :object
  relationable :as => :target

  has_many :roles, :through => :targets
  validates :name, :uname, :owner_id, :presence => true
  validates :name, :uname, :uniqueness => true
  validates :uname, :format => { :with => /^[a-zA-Z0-9_]+$/ }, :allow_nil => false, :allow_blank => false
  #TODO: Replace this simple cross-table uniq validation by more progressive analog
  validate lambda {
    errors.add(:uname, I18n.t('flash.group.user_uname_exists')) if User.exists? :uname => uname
  }

  belongs_to :global_role, :class_name => 'Role'

  belongs_to :owner, :class_name => 'User'
  has_many :own_projects, :as => :owner, :class_name => 'Project'

  has_many :objects, :as => :target, :class_name => 'Relation'
  has_many :targets, :as => :object, :class_name => 'Relation'

  has_many :members,      :through => :objects, :source => :object, :source_type => 'User',       :autosave => true
  has_many :projects,     :through => :targets, :source => :target, :source_type => 'Project',    :autosave => true
  has_many :platforms,    :through => :targets, :source => :target, :source_type => 'Platform',   :autosave => true
  has_many :repositories, :through => :targets, :source => :target, :source_type => 'Repository', :autosave => true

  include PersonalRepository

  before_save :create_dir
  after_destroy :remove_dir

  def roles_of(user)
    objects.where(:object_id => user.id, :object_type => user.class).map {|rel| rel.role}.reject {|r| r.nil?}
  end

  def add_role(user, role)
    roles = objects.where(:object_id => user.id, :object_type => user.class).map {|rel| rel.role}.reject {|r| r.nil?}
    unless roles.include? role
      rel = Relation.create(:object_type => user.class.to_s, :object_id => user.id,
                            :target_type => self.class.to_s, :target_id => id)
      rel.role = role
      rel.save
    end
  end

  def path
    build_path(uname)
  end

  protected

    def build_path(dir)
      File.join(APP_CONFIG['root_path'], 'groups', dir)
    end

    def create_dir
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} already exists" if exists
      if new_record?
        FileUtils.mkdir_p(path)
      elsif uname_changed?
        FileUtils.mv(build_path(uname_was), build_path(uname))
      end 
    end

    def remove_dir
      exists = File.exists?(path) && File.directory?(path)
      raise "Directory #{path} didn't exists" unless exists
      FileUtils.rm_rf(path)
    end

end
