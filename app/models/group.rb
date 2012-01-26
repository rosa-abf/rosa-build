class Group < ActiveRecord::Base
  MAX_OWN_PROJECTS = 32000
  belongs_to :owner, :class_name => 'User'

  has_many :own_projects, :as => :owner, :class_name => 'Project'

  has_many :relations, :as => :object, :dependent => :destroy
  has_many :objects, :as => :target, :class_name => 'Relation'
  has_many :targets, :as => :object, :class_name => 'Relation'

  has_many :members,      :through => :objects, :source => :object, :source_type => 'User',       :autosave => true
  has_many :projects,     :through => :targets, :source => :target, :source_type => 'Project',    :autosave => true
  has_many :platforms,    :through => :targets, :source => :target, :source_type => 'Platform',   :autosave => true
  has_many :repositories, :through => :targets, :source => :target, :source_type => 'Repository', :autosave => true

  validates :name, :owner, :presence => true
  validates :uname, :presence => true, :uniqueness => {:case_sensitive => false}, :format => { :with => /^[a-z0-9_]+$/ }
  validate { errors.add(:uname, :taken) if User.where('uname LIKE ?', uname).present? }
  validate { errors.add(:own_projects_count, :less_than_or_equal_to, :count => MAX_OWN_PROJECTS) if own_projects.size >= MAX_OWN_PROJECTS }

  attr_readonly :uname, :own_projects_count

  delegate :ssh_key, :to => :owner

  after_create :add_owner_to_members

  include Modules::Models::PersonalRepository
#  include Modules::Models::Owner

  protected
    def add_owner_to_members
      Relation.create_with_role(self.owner, self, 'admin')
#      members << self.owner if !members.exists?(:id => self.owner.id)
    end
end
