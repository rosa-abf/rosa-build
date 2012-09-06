# -*- encoding : utf-8 -*-
class Repository < ActiveRecord::Base
  belongs_to :platform

  has_many :project_to_repositories, :dependent => :destroy, :validate => true
  has_many :projects, :through => :project_to_repositories
  has_one  :key_pair, :dependent => :destroy

  validates :description, :presence => true
  validates :name, :uniqueness => {:scope => :platform_id, :case_sensitive => false}, :presence => true, :format => {:with => /^[a-z0-9_\-]+$/}

  scope :recent, order("name ASC")

  before_create :xml_rpc_create, :unless => lambda {Thread.current[:skip]}
  before_destroy :xml_rpc_destroy, :unless => lambda {Thread.current[:skip]}

  attr_accessible :name, :description, :publish_wtihout_qa
  attr_readonly :name, :platform_id

  def base_clone(attrs = {})
    dup.tap do |c|
      c.platform_id = nil
      attrs.each {|k,v| c.send("#{k}=", v)}
      c.updated_at = nil; c.created_at = nil
    end
  end

  def clone_relations(from)
    with_skip do
      from.projects.find_each {|p| self.projects << p}
    end
  end
  later :clone_relations, :loner => true, :queue => :clone_build

  def full_clone(attrs = {})
    base_clone(attrs).tap do |c|
      with_skip {c.save} and c.clone_relations(self) # later with resque
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
