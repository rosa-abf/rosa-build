# -*- encoding : utf-8 -*-
class Project < ActiveRecord::Base
  VISIBILITIES = ['open', 'hidden']
  MAX_OWN_PROJECTS = 32000

  belongs_to :category, :counter_cache => true
  belongs_to :owner, :polymorphic => true, :counter_cache => :own_projects_count

  has_many :issues, :dependent => :destroy
  has_many :build_lists, :dependent => :destroy
  has_many :auto_build_lists, :dependent => :destroy

  has_many :project_imports, :dependent => :destroy
  has_many :project_to_repositories, :dependent => :destroy
  has_many :repositories, :through => :project_to_repositories

  has_many :relations, :as => :target, :dependent => :destroy
  has_many :collaborators, :through => :relations, :source => :object, :source_type => 'User'
  has_many :groups,        :through => :relations, :source => :object, :source_type => 'Group'

  validates :name, :uniqueness => {:scope => [:owner_id, :owner_type], :case_sensitive => false}, :presence => true, :format => { :with => /^[a-zA-Z0-9_\-\+\.]+$/ }
  validates :owner, :presence => true
  validate { errors.add(:base, :can_have_less_or_equal, :count => MAX_OWN_PROJECTS) if owner.projects.size >= MAX_OWN_PROJECTS }
  # validate {errors.add(:base, I18n.t('flash.project.save_warning_ssh_key')) if owner.ssh_key.blank?}
  validates_attachment_size :srpm, :less_than => 500.megabytes
  validates_attachment_content_type :srpm, :content_type => ['application/octet-stream', "application/x-rpm", "application/x-redhat-package-manager"], :message => I18n.t('layout.invalid_content_type')

  #attr_accessible :category_id, :name, :description, :visibility
  attr_readonly :name

  scope :recent, order("name ASC")
  scope :by_name, lambda {|name| where('projects.name ILIKE ?', name)}
  scope :by_visibilities, lambda {|v| {:conditions => ['visibility in (?)', v.join(',')]}}
  scope :addable_to_repository, lambda { |repository_id| where("projects.id NOT IN (SELECT project_to_repositories.project_id FROM project_to_repositories WHERE (project_to_repositories.repository_id = #{ repository_id }))") }
  scope :automateable, where("projects.id NOT IN (SELECT auto_build_lists.project_id FROM auto_build_lists)")

  after_create :attach_to_personal_repository
  after_create :create_git_repo
  after_save :create_wiki

  after_destroy :destroy_git_repo
  after_destroy :destroy_wiki
  after_save {|p| p.delay.import_attached_srpm if p.srpm?} # should be after create_git_repo
  # after_rollback lambda { destroy_git_repo rescue true if new_record? }

  has_ancestry

  has_attached_file :srpm

  include Modules::Models::Owner

  def auto_build
    auto_build_lists.each do |auto_build_list|
      build_lists.create(
        :pl => auto_build_list.pl,
        :bpl => auto_build_list.bpl,
        :arch => auto_build_list.arch,
        :project_version => versions.last,
        :build_requires => true,
        :update_type => 'bugfix') unless build_lists.for_creation_date_period(Time.current - 15.seconds, Time.current).present?
    end
  end

  def build_for(platform, user)  
    build_lists.create do |bl|
      bl.pl = platform
      bl.bpl = platform
      bl.update_type = 'recommended'
      bl.arch = Arch.find_by_name('x86_64') # Return i586 after mass rebuild
      # FIXME: Need to set "latest_#{platform.name}"
      bl.project_version = "latest_import_mandriva2011"
      bl.build_requires = false # already set as db default
      bl.user = user
      bl.auto_publish = true # already  set as db default
      bl.include_repos = [platform.repositories.find_by_name('main').id]
    end
  end

  def tags
    self.git_repository.tags #.sort_by{|t| t.name.gsub(/[a-zA-Z.]+/, '').to_i}
  end

  def branches
    self.git_repository.branches
  end

  def versions
    tags.map(&:name) + branches.map{|b| "latest_#{b.name}"}
  end

  def members
    collaborators + groups.map(&:members).flatten
  end

  def git_repository
    @git_repository ||= Git::Repository.new(path)
  end

  def git_repo_name
    File.join owner.uname, name
  end

  def wiki_repo_name
    File.join owner.uname, "#{name}.wiki"
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

  def path
    build_path(git_repo_name)
  end

  def wiki_path
    build_wiki_path(git_repo_name)
  end

  def xml_rpc_create(repository)
    result = BuildServer.create_project name, repository.platform.name, repository.name, path
    if result == BuildServer::SUCCESS
      return true
    else
      raise "Failed to create project #{name} (repo #{repository.name}) inside platform #{repository.platform.name} in path #{path} with code #{result}."
    end
  end

  def xml_rpc_destroy(repository)
    result = BuildServer.delete_project name, repository.platform.name
    if result == BuildServer::SUCCESS
      return true
    else
      raise "Failed to delete repository #{name} (repo main) inside platform #{owner.uname}_personal with code #{result}."
    end
  end

  def platforms
    @platforms ||= repositories.map(&:platform).uniq
  end

  def import_srpm(srpm_path = srpm.path, branch_name = 'import')
    system("#{Rails.root.join('bin', 'import_srpm.sh')} #{srpm_path} #{path} #{branch_name} >> /dev/null 2>&1")
  end

  class << self
    def commit_comments(commit, project)
     comments = Comment.where(:commentable_id => commit.id, :commentable_type => 'Grit::Commit').order(:created_at)
     comments.each {|x| x.project = project; x.helper}
    end
  end

  def owner?(user)
    owner == user
  end

  protected

  def build_path(dir)
    File.join(APP_CONFIG['root_path'], 'git_projects', "#{dir}.git")
  end

  def build_wiki_path(dir)
    File.join(APP_CONFIG['root_path'], 'git_projects', "#{dir}.wiki.git")
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

  def import_attached_srpm
    if srpm?
      import_srpm # srpm.path
      self.srpm = nil; save # clear srpm
    end
  end


  def create_wiki
    if has_wiki && !FileTest.exist?(wiki_path)
      Grit::Repo.init_bare(wiki_path)
      wiki = Gollum::Wiki.new(wiki_path, {:base_path => Rails.application.routes.url_helpers.project_wiki_index_path(self)})
      wiki.write_page('Home', :markdown, I18n.t("wiki.seed.welcome_content"),
                      {:name => owner.name, :email => owner.email, :message => 'Initial commit'})
    end
  end

  def destroy_wiki
    FileUtils.rm_rf wiki_path
  end

end
