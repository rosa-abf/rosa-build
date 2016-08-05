class Repository < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: [:finders]

  include EventLoggable
  include EmptyMetadata

  LOCK_FILE_NAMES = { sync: '.sync.lock', repo: '.repo.lock' }
  SORT = { 'base' => 1, 'main' => 2, 'contrib' => 3, 'non-free' => 4, 'restricted' => 5 }

  belongs_to :platform

  has_many :relations, as: :target, dependent: :destroy
  has_many :actors, as: :target, class_name: 'Relation', dependent: :destroy
  has_many :members, through: :actors, source: :actor, source_type: 'User'

  has_many :project_to_repositories, dependent: :destroy, validate: true
  has_many :projects, through: :project_to_repositories
  has_many :repository_statuses, dependent: :destroy
  has_one  :key_pair, dependent: :destroy

  has_many :build_lists, foreign_key: :save_to_repository_id, dependent: :destroy

  validates :description, presence: true,
            length: { maximum: 100 }

  validates :name, uniqueness: { scope: :platform_id, case_sensitive: false },
            presence: true,
            format: { with: /\A[a-z0-9_\-]+\z/ },
            length: { maximum: 100 }

  validates :publish_builds_only_from_branch, length: { maximum: 255 }

  scope :recent, -> { order(:name) }
  scope :main,   -> { where(name: %w(main base)) }

  before_destroy  :detele_directory

  attr_readonly :name, :platform_id
  attr_accessor :projects_list, :build_for_platform_id

  def regenerate(build_for_platform_id = nil)
    build_for_platform = Platform.main.find build_for_platform_id if platform.personal?
    status = repository_statuses.find_or_create_by(platform_id: build_for_platform.try(:id) || platform_id)
    status.regenerate
  end

  def resign
    if platform.main?
      status = repository_statuses.find_or_create_by(platform_id: platform_id)
      status.resign
    end
  end

  def base_clone(attrs = {})
    dup.tap do |c|
      c.platform_id = nil
      attrs.each {|k,v| c.send("#{k}=", v)}
      c.updated_at = nil; c.created_at = nil
    end
  end

  def clone_relations(from)
    with_skip do
      from.projects.find_each {|p| self.projects << p if self.projects.exclude?(p)}
    end
  end
  later :clone_relations, loner: true, queue: :low

  def add_projects(list, user)
    list.lines.each do |line|
      begin
        line.chomp!; line.strip!
        owner, name = line.split('/')
        next if owner.blank? || name.blank?

        project = ProjectPolicy::Scope.new(user, Project).read.where(owner_uname: owner, name: name).first
        projects << project if project
      rescue RuntimeError, Exception
      end
    end
  end
  later :add_projects, queue: :middle

  def remove_projects(list)
    list.lines.each do |name|
      begin
        name.chomp!; name.strip!
        next if name.blank?
        project_to_repositories.where(projects: { name: name }).joins(:project).readonly(false).destroy_all
      rescue RuntimeError, Exception
      end
    end
  end
  later :remove_projects, queue: :middle

  def full_clone(attrs = {})
    base_clone(attrs).tap do |c|
      with_skip {c.save} and c.clone_relations(self) # later with resque
    end
  end

  # Checks locking of sync
  def sync_lock_file_exists?
    lock_file_actions :check, :sync
  end

  # Uses for locking sync
  # Calls from UI
  def add_sync_lock_file
    lock_file_actions :add, :sync
  end

  # Uses for unlocking sync
  # Calls from UI
  def remove_sync_lock_file
    lock_file_actions :remove, :sync
  end

  # Uses for locking publishing
  # Calls from API
  def add_repo_lock_file
    lock_file_actions :add, :repo
  end

  # Uses for unlocking publishing
  # Calls from API
  def remove_repo_lock_file
    lock_file_actions :remove, :repo
  end

  # Presence of `.repo.lock` file means that mirror is currently synchronising the repository state.
  def repo_lock_file_exists?
    lock_file_actions :check, :repo
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
  later :destroy, queue: :low

  def self.custom_sort(repos)
    repos.select{ |r| SORT.keys.include?(r.name) }.sort{ |a,b| SORT[a.name] <=>  SORT[b.name] } | repos.sort_by(&:name)
  end

  protected

  def lock_file_actions(action, lock_file)
    result = false
    (['SRPMS'] << Arch.pluck(:name)).each do |arch|
      path = "#{platform.path}/repository/#{arch}/#{name}/#{LOCK_FILE_NAMES[lock_file]}"
      case action
      when :add
        result ||= FileUtils.touch(path) rescue nil
      when :remove
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
