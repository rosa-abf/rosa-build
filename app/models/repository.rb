# -*- encoding : utf-8 -*-
class Repository < ActiveRecord::Base
  belongs_to :platform

  has_many :project_to_repositories, :dependent => :destroy, :validate => true
  has_many :projects, :through => :project_to_repositories

  validates :description, :presence => true
  validates :name, :uniqueness => {:scope => :platform_id, :case_sensitive => false}, :presence => true, :format => {:with => /^[a-z0-9_\-]+$/}

  scope :recent, order("name ASC")

  before_create :xml_rpc_create, :unless => lambda {Thread.current[:skip]}
  before_destroy :xml_rpc_destroy

  attr_accessible :description, :name

  def base_clone(attrs = {})
    clone.tap do |c| # dup
      c.platform_id = nil
      attrs.each {|k,v| c.send("#{k}=", v)}
      c.updated_at = nil; c.created_at = nil # :id = nil
    end
  end

  def clone_relations(from)
    with_skip do
      from.projects.find_each {|p| self.projects << p}
    end
  end

  def full_clone(attrs = {})
    base_clone(attrs).tap do |c|
      with_skip {c.save} and c.delay.clone_relations(self)
    end
  end

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
      raise "Failed to delete repository #{name} inside platform #{platform.name} with code #{result}."
    end
  end
end
