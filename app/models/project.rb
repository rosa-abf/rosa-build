# -*- encoding : utf-8 -*-
class Project < ActiveRecord::Base
  VISIBILITIES = ['open', 'hidden']
  MAX_OWN_PROJECTS = 32000

  belongs_to :owner, :polymorphic => true, :counter_cache => :own_projects_count

  has_many :issues, :dependent => :destroy
  has_many :build_lists, :dependent => :destroy

  has_many :project_imports, :dependent => :destroy
  has_many :project_to_repositories, :dependent => :destroy
  has_many :repositories, :through => :project_to_repositories

  has_many :relations, :as => :target, :dependent => :destroy
  has_many :collaborators, :through => :relations, :source => :object, :source_type => 'User'
  has_many :groups,        :through => :relations, :source => :object, :source_type => 'Group'
  has_many :labels

  validates :name, :uniqueness => {:scope => [:owner_id, :owner_type], :case_sensitive => false}, :presence => true, :format => {:with => /^[a-zA-Z0-9_\-\+\.]+$/}
  validates :owner, :presence => true
  validate { errors.add(:base, :can_have_less_or_equal, :count => MAX_OWN_PROJECTS) if owner.projects.size >= MAX_OWN_PROJECTS }

  validates_attachment_size :srpm, :less_than => 500.megabytes
  validates_attachment_content_type :srpm, :content_type => ['application/octet-stream', "application/x-rpm", "application/x-redhat-package-manager"], :message => I18n.t('layout.invalid_content_type')

  attr_accessible :name, :description, :visibility, :srpm, :is_rpm, :default_branch, :has_issues, :has_wiki
  attr_readonly :name

  scope :recent, order("name ASC")
  scope :search_order, order("CHAR_LENGTH(name) ASC")
  scope :search, lambda {|q| by_name("%#{q.strip}%")}
  scope :by_name, lambda {|name| where('projects.name ILIKE ?', name)}
  scope :by_visibilities, lambda {|v| where(:visibility => v)}
  scope :opened, where(:visibility => 'open')
  scope :addable_to_repository, lambda { |repository_id| where("projects.id NOT IN (SELECT project_to_repositories.project_id FROM project_to_repositories WHERE (project_to_repositories.repository_id = #{ repository_id }))") }

  after_create :attach_to_personal_repository
  after_create :create_git_repo
  after_create {|p| p.delay(:queue => 'fork', :priority => 20).fork_git_repo unless is_root?}
  after_save :create_wiki

  after_destroy :destroy_git_repo
  after_destroy :destroy_wiki
  after_save {|p| p.delay(:queue => 'import', :priority => 10).import_attached_srpm if p.srpm?} # should be after create_git_repo
  # after_rollback lambda { destroy_git_repo rescue true if new_record? }

  has_ancestry

  has_attached_file :srpm

  include Modules::Models::Owner

  def build_for(platform, user, arch = 'i586') # Return i586 after mass rebuild
    arch = Arch.find_by_name(arch) if arch.acts_like?(:string)
    build_lists.create do |bl|
      bl.pl = platform
      bl.bpl = platform
      bl.update_type = 'newpackage'
      bl.arch = arch
      bl.project_version = "latest_#{platform.name}" # "latest_import_mandriva2011"
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

  def last_active_branch
    @last_active_branch ||= branches.inject do |r, c|
      r_last = r.commit.committed_date || r.commit.authored_date unless r.nil?
      c_last = c.commit.committed_date || c.commit.authored_date
      if r.nil? or r_last < c_last
        r = c
      end
      r
    end
    @last_active_branch
  end

  def branch(name = nil)
    name = default_branch if name.blank?
    branches.select{|b| b.name == name}.first
  end

  def tree_info(tree, treeish = nil, path = nil)
    treeish = tree.id unless treeish.present?
    # initialize result as hash of <tree_entry> => nil
    res = (tree.trees.sort + tree.blobs.sort).inject({}){|h, e| h.merge!({e => nil})}
    # fills result vith commits that describes this file
    res = res.inject(res) do |h, (entry, commit)|
      # only if commit == nil ...
      if commit.nil? and entry.respond_to? :name
        # ... find last commit corresponds to this file ...
        c = git_repository.log(treeish, File.join([path, entry.name].compact), :max_count => 1).first
        # ... and add it to result.
        h[entry] = c
        # find another files, that linked to this commit and set them their commit
        # c.diffs.map{|diff| diff.b_path.split(File::SEPARATOR, 2).first}.each do |name|
        #   h.each_pair do |k, v|
        #     h[k] = c if k.name == name and v.nil?
        #   end
        # end
      end
      h
    end
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
    dup.tap do |c|
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

  def self.commit_comments(commit, project)
    comments = Comment.where(:commentable_id => commit.id.hex, :commentable_type => 'Grit::Commit')
  end

  def owner?(user)
    owner == user
  end

  def self.process_hook(owner_uname, repo, newrev, oldrev, ref, newrev_type, oldrev_type)
    rec = GitHook.new(owner_uname, repo, newrev, oldrev, ref, newrev_type, oldrev_type)
    ActivityFeedObserver.instance.after_create rec
  end

  def owner_and_admin_ids
    recipients = self.relations.by_role('admin').where(:object_type => 'User').map { |rel| rel.read_attribute(:object_id) }
    recipients = recipients | [self.owner_id] if self.owner_type == 'User'
    recipients
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
    if is_root?
      Grit::Repo.init_bare(path)
      write_hook.delay(:queue => 'fork', :priority => 15)
    end
  end

  def fork_git_repo
    dummy = Grit::Repo.new(path) rescue parent.git_repository.repo.fork_bare(path)
    write_hook
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

  def write_hook
    is_production = Rails.env == "production"
    hook = File.join(::Rails.root.to_s, 'tmp', "post-receive-hook")
    FileUtils.cp(File.join(::Rails.root.to_s, 'bin', "post-receive-hook.partial"), hook)
    File.open(hook, 'a') do |f|
      s = "\n  /bin/bash -l -c \"cd #{is_production ? '/srv/rosa_build/current' : Rails.root.to_s} && #{is_production ? 'RAILS_ENV=production' : ''} bundle exec rails runner 'Project.delay(:queue => \\\"hook\\\").process_hook(\\\"$owner\\\", \\\"$reponame\\\", \\\"$newrev\\\", \\\"$oldrev\\\", \\\"$ref\\\", \\\"$newrev_type\\\", \\\"$oldrev_type\\\")'\""
      s << " > /dev/null 2>&1" if is_production
      s << "\ndone\n"
      f.write(s)
      f.chmod(0755)
    end

    hook_file = File.join(path, 'hooks', 'post-receive')
    FileUtils.cp(hook, hook_file)
    FileUtils.rm_rf(hook)

  rescue Exception # FIXME
  end
end
