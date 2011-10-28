class Group < ActiveRecord::Base
  relationable :as => :object
  relationable :as => :target

  belongs_to :global_role, :class_name => 'Role'
  belongs_to :owner, :class_name => 'User'

  has_many :own_projects, :as => :owner, :class_name => 'Project'

  has_many :objects, :as => :target, :class_name => 'Relation'
  has_many :targets, :as => :object, :class_name => 'Relation'
  has_many :roles, :through => :targets

  has_many :members,      :through => :objects, :source => :object, :source_type => 'User',       :autosave => true
  has_many :projects,     :through => :targets, :source => :target, :source_type => 'Project',    :autosave => true
  has_many :platforms,    :through => :targets, :source => :target, :source_type => 'Platform',   :autosave => true
  has_many :repositories, :through => :targets, :source => :target, :source_type => 'Repository', :autosave => true

  validates :name, :uname, :owner_id, :presence => true
  validates :name, :uname, :uniqueness => true
  validates :uname, :format => { :with => /^[a-zA-Z0-9_]+$/ }, :allow_nil => false, :allow_blank => false
  validate { errors.add(:uname, :taken) if User.where('uname LIKE ?', uname).present? }

  attr_readonly :uname

  delegate :ssh_key, :to => :owner

  include PersonalRepository

#  before_save :create_dir
#  after_destroy :remove_dir

  before_create :add_default_role
  before_save :add_owner_rel

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

  protected

    def add_owner_rel
      if new_record? and owner
        add_owner owner
      elsif owner_id_changed?
        remove_owner owner_type_was.classify.find(owner_id_was)
        add_owner owner
      end
    end
end
