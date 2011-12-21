class Repository < ActiveRecord::Base
  belongs_to :platform
  belongs_to :owner, :polymorphic => true

  has_many :projects, :through => :project_to_repositories #, :dependent => :destroy
  has_many :project_to_repositories, :validate => true, :dependent => :destroy

  has_many :relations, :as => :target, :dependent => :destroy
  has_many :objects, :as => :target, :class_name => 'Relation', :dependent => :destroy
  has_many :members, :through => :objects, :source => :object, :source_type => 'User'
  has_many :groups,  :through => :objects, :source => :object, :source_type => 'Group'

  validates :description, :uniqueness => {:scope => :platform_id}, :presence => true
  validates :name, :uniqueness => {:scope => :platform_id}, :presence => true, :format => { :with => /^[a-z0-9_\-]+$/ }
  # validates :platform_id, :presence => true # if you uncomment this platform clone will not work

  scope :recent, order("name ASC")

  before_create :xml_rpc_create, :unless => lambda {Thread.current[:skip]}
  before_destroy :xml_rpc_destroy
  after_create :add_admin_relations

  attr_accessible :description, :name #, :platform_id

  def full_clone(attrs) # owner
    clone.tap do |c| # dup
      c.attributes = attrs
      c.updated_at = nil; c.created_at = nil # :id = nil
      c.projects = projects
    end
  end

  include Modules::Models::Owner

  class << self
    def build_stub(platform)
      rep = Repository.new
      rep.platform = platform
      rep
    end
  end

  protected

    def xml_rpc_create
      result = BuildServer.create_repo name, platform.name
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to create repository #{name} inside platform #{platform.name} with code #{result}."
      end      
    end

    def xml_rpc_destroy
      result = BuildServer.delete_repo name, platform.name
      if result == BuildServer::SUCCESS
        return true
      else
        raise "Failed to delete repository #{name} inside platform #{platform.name}."
      end
    end

    def add_admin_relations
      platform.relations.where(:role => 'admin').each do |rel|
        if !relations.exists?(:role => 'admin', :object_type => rel.object_type, :object_id => rel.object_id) && rel.object != owner
          r = relations.build(:role => 'admin', :object_type => rel.object_type)
          r.object_id = rel.object_id
          r.save
        end
      end
    end
end
