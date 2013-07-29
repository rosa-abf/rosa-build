# -*- encoding : utf-8 -*-
class Repository < ActiveRecord::Base
  SORT = {'base' => 1, 'main' => 2, 'contrib' => 3, 'non-free' => 4, 'restricted' => 5}

  belongs_to :platform

  has_many :relations, :as => :target, :dependent => :destroy
  has_many :actors, :as => :target, :class_name => 'Relation', :dependent => :destroy
  has_many :members, :through => :actors, :source => :actor, :source_type => 'User'

  has_many :project_to_repositories, :dependent => :destroy, :validate => true
  has_many :projects, :through => :project_to_repositories
  has_one  :key_pair, :dependent => :destroy

  has_many :build_lists, :foreign_key => :save_to_repository_id, :dependent => :destroy

  validates :description, :presence => true
  validates :name, :uniqueness => {:scope => :platform_id, :case_sensitive => false}, :presence => true, :format => {:with => /\A[a-z0-9_\-]+\z/}

  scope :recent, order("#{table_name}.name ASC")

  before_destroy :detele_directory

  attr_accessible :name, :description, :publish_without_qa
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

  # Checks locking of sync
  def sync_lock_file_exists?
    sync_actions :check
  end

  # Uses for locking sync
  # Calls from UI
  def add_sync_lock_file
    sync_actions :lock
  end

  # Uses for unlocking sync
  # Calls from UI
  def remove_sync_lock_file
    sync_actions :unlock
  end

  # Uses for locking publishing
  # Calls from API
  def add_repo_lock_file
    sync_actions :lock, '.repo.lock'
  end

  # Uses for unlocking publishing
  # Calls from API
  def remove_repo_lock_file
    sync_actions :unlock, '.repo.lock'
  end

  def add_member(member, role = 'admin')
    Relation.add_member(member, self, role)
  end

  def remove_member(member)
    Relation.remove_member(member, self)
  end

  class << self
    def build_stub(platform)
      rep = Repository.new
      rep.platform = platform
      rep
    end
  end

  def destroy
    with_skip {super} # avoid cascade XML RPC requests
  end
  later :destroy, :queue => :clone_build

  def self.custom_sort(repos)
    repos.select{ |r| SORT.keys.include?(r.name) }.sort{ |a,b| SORT[a.name] <=>  SORT[b.name] } | repos.sort_by(&:name)
  end

  protected

  def sync_actions(action, lock_file = '.sync.lock')
    result = false
    (['SRPMS'] << Arch.pluck(:name)).each do |arch|
      path = "#{platform.path}/repository/#{arch}/#{name}/#{lock_file}"
      case action
      when :lock
        result ||= FileUtils.touch(path) rescue nil
      when :unlock
        result ||= FileUtils.rm_f(path)
      when :check
        return true if File.exist?(path)
      end
    end
    return result
  end

  def detele_directory
    return unless platform
    repository_path = platform.path << '/repository'
    if platform.personal?
      Platform.main.pluck(:name).each do |main_platform_name|
        detele_repositories_directory "#{repository_path}/#{main_platform_name}"
      end
    else
      detele_repositories_directory repository_path
    end
  end

  def detele_repositories_directory(repository_path)
    srpm_and_arches = (['SRPM'] << Arch.pluck(:name)).join(',')
    `bash -c 'rm -rf #{repository_path}/{#{srpm_and_arches}}/#{name}'`
  end

end
