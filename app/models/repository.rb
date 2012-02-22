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

  def full_clone(attrs = {})
    clone.tap do |c| # dup
      c.attributes = attrs # do not set protected
      c.platform_id = nil; c.updated_at = nil; c.created_at = nil # :id = nil
      c.projects = projects
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
