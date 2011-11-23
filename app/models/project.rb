class Project < ActiveRecord::Base
  VISIBILITIES = ['open', 'hidden']

  belongs_to :category, :counter_cache => true
  belongs_to :owner, :polymorphic => true

  has_many :build_lists, :dependent => :destroy
  has_many :auto_build_lists, :dependent => :destroy

  has_many :project_to_repositories, :dependent => :destroy
  has_many :repositories, :through => :project_to_repositories

  has_many :relations, :as => :target, :dependent => :destroy
  has_many :collaborators, :through => :relations, :source => :object, :source_type => 'User'
  has_many :groups,        :through => :relations, :source => :object, :source_type => 'Group'

  validates :name,     :uniqueness => {:scope => [:owner_id, :owner_type]}, :presence => true
  validates :unixname, :uniqueness => {:scope => [:owner_id, :owner_type]}, :presence => true, :format => { :with => /^[a-z0-9_\-\+\.]+$/ }
  validates :owner, :presence => true
  # validate {errors.add(:base, I18n.t('flash.project.save_warning_ssh_key')) if owner.ssh_key.blank?}

  #attr_accessible :category_id, :name, :unixname, :description, :visibility
  attr_readonly :unixname

  scope :recent, order("name ASC")
  scope :by_name, lambda { |name| where('name like ?', '%' + name + '%') }
  scope :by_visibilities, lambda {|v| {:conditions => ['visibility in (?)', v.join(',')]}}
  scope :addable_to_repository, lambda { |repository_id| where("projects.id NOT IN (SELECT project_to_repositories.project_id FROM project_to_repositories WHERE (project_to_repositories.repository_id = #{ repository_id }))") }
  scope :automateable, where("projects.id NOT IN (SELECT auto_build_lists.project_id FROM auto_build_lists)")

  after_create :make_owner_rel
  after_create :attach_to_personal_repository
  after_create :create_git_repo
  after_destroy :destroy_git_repo
  # after_rollback lambda { destroy_git_repo rescue true if new_record? }

  has_ancestry

  def auto_build
    auto_build_lists.each do |auto_build_list|
      build_lists.create(
        :pl => auto_build_list.pl,
        :bpl => auto_build_list.bpl,
        :arch => auto_build_list.arch,
        :project_version => collected_project_versions.last,
        :build_requires => true,
        :update_type => 'bugfix') unless build_lists.for_creation_date_period(Time.current - 15.seconds, Time.current).present?
    end
  end

  def project_versions
    res = tags.select{|tag| tag.name =~ /^v\./}
    return res if res and res.size > 0
    tags
  end

  def collected_project_versions
    project_versions.collect{|tag| tag.name.gsub(/^\w+\./, "")}
  end

  def tags
    self.git_repository.tags.sort_by{|t| t.name.gsub(/[a-zA-Z.]+/, '').to_i}
  end

  def members
    collaborators + groups.map(&:members).flatten
  end

  def git_repository
    @git_repository ||= Git::Repository.new(path)
  end

  def git_repo_name
    File.join owner.uname, unixname
  end

  def public?
    visibility == 'open'
  end

  def fork(new_owner)
    clone.tap do |c|
      c.parent_id = id
      c.owner = new_owner
      c.updated_at = nil; c.created_at = nil # :id = nil
      c.save
    end
  end

  def add_to_repository(platf, repo)
    result = BuildServer.add_to_repo(repository.name, platf.name)
    if result == BuildServer::SUCCESS
      return true
    else
      raise "Failed to add project #{name} to repo #{repo.name} of platform #{platf.name} with code #{result}."
    end      
  end

  def path
    build_path(git_repo_name)
  end

  def xml_rpc_create(repository)
    result = BuildServer.create_project unixname, repository.platform.unixname, repository.unixname, path
    if result == BuildServer::SUCCESS
      return true
    else
      raise "Failed to create project #{unixname} (repo #{repository.unixname}) inside platform #{repository.platform.unixname} in path #{path} with code #{result}."
    end      
  end

  def xml_rpc_destroy(repository)
    result = BuildServer.delete_project unixname, repository.platform.unixname
    if result == BuildServer::SUCCESS
      return true
    else
      raise "Failed to delete repository #{name} (repo main) inside platform #{owner.uname}_personal with code #{result}."
    end
  end

  protected

    def build_path(dir)
      File.join(APP_CONFIG['root_path'], 'git_projects', "#{dir}.git")
    end

    def attach_to_personal_repository
      repositories << self.owner.personal_repository if !repositories.exists?(:id => self.owner.personal_repository)
    end

    def create_git_repo
      is_root? ? Grit::Repo.init_bare(path) : parent.git_repository.repo.delay.fork_bare(path)
    end

    def destroy_git_repo
      FileUtils.rm_rf path
    end

    def make_owner_rel
      relations.create :object_id => owner_id, :object_type => owner_type, :role => 'admin'
    end
end
