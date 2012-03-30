# -*- encoding : utf-8 -*-
class Group < ActiveRecord::Base
  belongs_to :owner, :class_name => 'User'

  has_many :relations, :as => :object, :dependent => :destroy
  has_many :objects, :as => :target, :class_name => 'Relation'
  has_many :targets, :as => :object, :class_name => 'Relation'

  has_many :members,      :through => :objects, :source => :object, :source_type => 'User',       :autosave => true
  has_many :projects,     :through => :targets, :source => :target, :source_type => 'Project',    :autosave => true
  has_many :platforms,    :through => :targets, :source => :target, :source_type => 'Platform',   :autosave => true

  has_many :own_projects, :as => :owner, :class_name => 'Project', :dependent => :destroy
  has_many :own_platforms, :as => :owner, :class_name => 'Platform', :dependent => :destroy

  validates :owner, :presence => true
  validates :uname, :presence => true, :uniqueness => {:case_sensitive => false}, :format => { :with => /^[a-z0-9_]+$/ }
  validate { errors.add(:uname, :taken) if User.where('uname LIKE ?', uname).present? }

  scope :search_order, order("CHAR_LENGTH(uname) ASC")
  scope :without, lambda {|a| where("groups.id NOT IN (?)", a)}
  scope :search, lambda {|q| where("uname ILIKE ?", "%#{q.strip}%")}
  scope :opened, where('1=1')
  scope :by_owner, lambda {|owner| where(:owner_id => owner.id)}
  scope :by_admin, lambda {|admin| joins(:relations).where(:'relations.role' => 'admin', :'relations.target_id' => admin.id, :'relations.target_type' => 'User')}

  attr_accessible :description
  attr_readonly :own_projects_count

  delegate :email, :to => :owner

  after_create :add_owner_to_members

  include Modules::Models::PersonalRepository
  # include Modules::Models::Owner

  def self.can_own_project(user)
    (by_owner(user) | by_admin(user)).collect { |el| [el.name, el.id] }
  end

  def name
    uname
  end

  protected

  def add_owner_to_members
    Relation.create_with_role(self.owner, self, 'admin')
    # members << self.owner if !members.exists?(:id => self.owner.id)
  end
end
