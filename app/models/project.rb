class Project < ActiveRecord::Base
  include Autostart
  include Owner
  include Git
  include Wiki
  include UrlHelper
  include EventLoggable

  VISIBILITIES = ['open', 'hidden']
  MAX_OWN_PROJECTS = 32000
  NAME_REGEXP = /[\w\-\+\.]+/

  belongs_to :owner, polymorphic: true, counter_cache: :own_projects_count
  belongs_to :maintainer, class_name: 'User'

  has_many :issues, dependent: :destroy
  has_many :pull_requests, dependent: :destroy, foreign_key: 'to_project_id'
  has_many :labels, dependent: :destroy

  has_many :project_imports, dependent: :destroy
  has_many :project_to_repositories, dependent: :destroy
  has_many :repositories, through: :project_to_repositories
  has_many :project_tags, dependent: :destroy
  has_many :project_statistics, dependent: :destroy

  has_many :build_lists, dependent: :destroy
  has_many :hooks, dependent: :destroy

  has_many :relations, as: :target, dependent: :destroy
  has_many :collaborators, through: :relations, source: :actor, source_type: 'User'
  has_many :groups,        through: :relations, source: :actor, source_type: 'Group'

  has_many :packages, class_name: 'BuildList::Package', dependent: :destroy
  has_and_belongs_to_many :advisories # should be without dependent: :destroy

  validates :name, uniqueness: { scope: [:owner_id, :owner_type], case_sensitive: false },
                   presence: true,
                   format: { with: /\A#{NAME_REGEXP}\z/,
                             message: I18n.t("activerecord.errors.project.uname") }
  validates :maintainer_id, presence: true, unless: :new_record?
  validates :url, presence: true, format: {with: /\Ahttps?:\/\/[\S]+\z/}, if: :mass_import
  validates :add_to_repository_id, presence: true, if: :mass_import
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validate { errors.add(:base, :can_have_less_or_equal, count: MAX_OWN_PROJECTS) if owner.projects.size >= MAX_OWN_PROJECTS }
  validate :check_default_branch
  # throws validation error message from ProjectToRepository model into Project model
  validate do |project|
    project.project_to_repositories.each do |p_to_r|
      next if p_to_r.valid?
      p_to_r.errors.full_messages.each{ |msg| errors[:base] << msg }
    end
    errors.delete :project_to_repositories
  end

  attr_accessible :name, :description, :visibility, :srpm, :is_package, :default_branch,
                  :has_issues, :has_wiki, :maintainer_id, :publish_i686_into_x86_64,
                  :url, :srpms_list, :mass_import, :add_to_repository_id, :architecture_dependent,
                  :autostart_status
  attr_readonly :owner_id, :owner_type

  scope :recent, -> { order(:name) }
  scope :search_order, -> { order('CHAR_LENGTH(projects.name) ASC') }
  scope :search, ->(q) {
    q = q.to_s.strip
    by_name("%#{q}%").search_order if q.present?
  }
  scope :by_name, ->(name) { where('projects.name ILIKE ?', name) if name.present? }
  scope :by_owner_and_name, ->(*params) {
    term = params.map(&:strip).join('/').downcase
    where("lower(concat(owner_uname, '/', name)) ILIKE ?", "%#{term}%") if term.present?
  }
  scope :by_visibilities, ->(v) { where(visibility: v) }
  scope :opened, -> { where(visibility: 'open') }
  scope :package, -> { where(is_package: true) }
  scope :addable_to_repository, ->(repository_id) {
    where('projects.id NOT IN (
            SELECT ptr.project_id
            FROM project_to_repositories AS ptr
            WHERE ptr.repository_id = ?)', repository_id)
  }
  scope :by_owners, ->(group_owner_ids, user_owner_ids) {
    where("projects.owner_id in (?) AND projects.owner_type = 'Group') OR
      (projects.owner_id in (?) AND projects.owner_type = 'User')", group_owner_ids, user_owner_ids)
  }

  before_validation :truncate_name, on: :create
  before_save -> { self.owner_uname = owner.uname if owner_uname.blank? || owner_id_changed? || owner_type_changed? }
  before_create :set_maintainer
  after_save :attach_to_personal_repository
  after_update :set_new_git_head
  after_update -> { update_path_to_project(name_was) }, if: :name_changed?

  has_ancestry orphan_strategy: :rootify #:adopt not available yet

  attr_accessor :url, :srpms_list, :mass_import, :add_to_repository_id

  class << self
    def find_by_owner_and_name(owner_name, project_name)
      where(owner_uname: owner_name, name: project_name).first ||
        by_owner_and_name(owner_name, project_name).first
    end

    def find_by_owner_and_name!(owner_name, project_name)
      find_by_owner_and_name(owner_name, project_name) or raise ActiveRecord::RecordNotFound
    end
  end

  def init_mass_import
    Project.perform_later :clone_build, :run_mass_import, url, srpms_list, visibility, owner, add_to_repository_id
  end

  def name_with_owner
    "#{owner_uname || owner.uname}/#{name}"
  end

  def to_param
    name
  end

  def all_members
    members | (owner_type == 'User' ? [owner] : owner.members)
  end

  def members
    collaborators | groups.map(&:members).flatten
  end

  def add_member(member, role = 'admin')
    Relation.add_member(member, self, role)
  end

  def remove_member(member)
    Relation.remove_member(member, self)
  end

  def platforms
    @platforms ||= repositories.map(&:platform).uniq
  end

  def admins
    admins = self.collaborators.where("relations.role = 'admin'")
    grs = self.groups.where("relations.role = 'admin'")
    if self.owner.is_a? Group
      grs = grs.where("relations.actor_id != ?", self.owner.id)
      admins = admins | owner.members.where("relations.role = 'admin'")
    end
    admins = admins | grs.map(&:members).flatten # member of the admin group is admin
  end

  def public?
    visibility == 'open'
  end

  def owner?(user)
    owner == user
  end

  def git_project_address auth_user
    opts = default_url_options
    opts.merge!({user: auth_user.authentication_token, password: ''}) unless self.public?
    Rails.application.routes.url_helpers.project_url(self.owner.uname, self.name, opts) + '.git'
    #path #share by NFS
  end

  def build_for(mass_build, repository_id, arch =  Arch.find_by_name('i586'), priority = 0, increase_rt = false)
    build_for_platform  = mass_build.build_for_platform
    save_to_platform    = mass_build.save_to_platform
    user                = mass_build.user
    # Select main and project platform repository(contrib, non-free and etc)
    # If main does not exist, will connect only project platform repository
    # If project platform repository is main, only main will be connect
    main_rep_id = build_for_platform.repositories.main.first.try(:id)
    include_repos = ([main_rep_id] << (save_to_platform.main? ? repository_id : nil)).compact.uniq

    project_version = project_version_for save_to_platform, build_for_platform

    increase_release_tag(project_version, user, "MassBuild##{mass_build.id}: Increase release tag") if increase_rt

    build_list = build_lists.build do |bl|
      bl.save_to_platform       = save_to_platform
      bl.build_for_platform     = build_for_platform
      bl.update_type            = 'newpackage'
      bl.arch                   = arch
      bl.project_version        = project_version
      bl.user                   = user
      bl.auto_publish_status    = mass_build.auto_publish? ? BuildList::AUTO_PUBLISH_STATUS_DEFAULT : BuildList::AUTO_PUBLISH_STATUS_NONE
      bl.include_repos          = include_repos
      bl.extra_repositories     = mass_build.extra_repositories
      bl.extra_build_lists      = mass_build.extra_build_lists
      bl.priority               = priority
      bl.mass_build_id          = mass_build.id
      bl.save_to_repository_id  = repository_id
    end
    build_list.save
  end

  def project_version_for(save_to_platform, build_for_platform)
    if repo.commits("#{save_to_platform.name}").try(:first).try(:id)
      save_to_platform.name
    elsif repo.commits("#{build_for_platform.name}").try(:first).try(:id)
      build_for_platform.name
    else
      default_branch
    end
  end

  def fork(new_owner, new_name = name)
    new_name = new_name.presence || name
    dup.tap do |c|
      c.name = new_name
      c.parent_id = id
      c.owner = new_owner
      c.updated_at = nil; c.created_at = nil # :id = nil
      # Hack to call protected method :)
      c.send :set_maintainer
      c.save
    end
  end

  def destroy_project_from_repository(repository)
    AbfWorker::BuildListsPublishTaskManager.destroy_project_from_repository self, repository
  end

  def default_head treeish = nil # maybe need change 'head'?
    # Attention!
    # repo.commit(nil) => <Grit::Commit "b6c0f81deb17590d22fc07ba0bbd4aa700256f61">
    # repo.commit(nil.to_s) => nil
    return treeish if treeish.present? && repo.commit(treeish).present?
    if repo.branches_and_tags.map(&:name).include?(treeish || default_branch)
      treeish || default_branch
    else
      repo.branches_and_tags[0].try(:name) || default_branch
    end
  end

  def get_project_tag_sha1(tag, format)
    format_id = ProjectTag::FORMATS["#{tag_file_format(format)}"]
    project_tag = project_tags.where(tag_name: tag.name, format_id: format_id).first

    return project_tag.sha1 if project_tag && project_tag.commit_id == tag.commit.id && FileStoreClean.file_exist_on_file_store?(project_tag.sha1)

    archive = archive_by_treeish_and_format tag.name, format
    sha1    = Digest::SHA1.file(archive[:path]).hexdigest
    unless FileStoreClean.file_exist_on_file_store? sha1
      token = User.find_by_uname('rosa_system').authentication_token
      begin
        resp = JSON `curl --user #{token}: -POST -F 'file_store[file]=@#{archive[:path]};filename=#{name}-#{tag.name}.#{tag_file_format(format)}' #{APP_CONFIG['file_store_url']}/api/v1/upload`
      rescue # Dont care about it
        resp = {}
      end
      return nil if resp['sha1_hash'].nil?
    end
    if project_tag
      project_tag.destroy_files_from_file_store(project_tag.sha1)
      project_tag.update_attributes(sha1: sha1)
    else
      project_tags.create(
        tag_name:  tag.name,
        format_id: format_id,
        commit_id: tag.commit.id,
        sha1:      sha1
      )
    end
    return sha1
  end

  def archive_by_treeish_and_format(treeish, format)
    @archive ||= create_archive treeish, format
  end

  # Finds release tag and increase its:
  # 'Release: %mkrel 4mdk' => 'Release: 5mdk'
  # 'Release: 4' => 'Release: 5'
  # Finds release macros and increase it:
  # '%define release %mkrel 4mdk' => '%define release 5mdk'
  # '%define release 4' => '%define release 5'
  def self.replace_release_tag(content)

    build_new_release = Proc.new do |release, combine_release|
      if combine_release.present?
        r = combine_release.split('.').last.to_i
        release << combine_release.gsub(/.[\d]+$/, '') << ".#{r + 1}"
      else
        release = release.to_i + 1
      end
      release
    end

    content.gsub(/^Release:(\s+)(%mkrel\s+)?(\d+)([.\d]+)?(mdk)?$/) do |line|
      tab, mkrel, mdk = $1, $2, $5
      "Release:#{tab}#{build_new_release.call($3, $4)}#{mdk}"
    end.gsub(/^%define\s+release:?(\s+)(%mkrel\s+)?(\d+)([.\d]+)?(mdk)?$/) do |line|
      tab, mkrel, mdk = $1, $2, $5
      "%define release#{tab}#{build_new_release.call($3, $4)}#{mdk}"
    end
  end

  class << self
    Autostart::HUMAN_AUTOSTART_STATUSES.each do |autostart_status, human_autostart_status|
      define_method "autostart_build_lists_#{human_autostart_status}" do
        autostart_build_lists autostart_status
      end
    end
  end

  def self.autostart_build_lists(autostart_status)
    Project.where(autostart_status: autostart_status).find_each do |p|
      p.project_to_repositories.autostart_enabled.includes(repository: :platform).each do |p_to_r|
        repository  = p_to_r.repository
        user        = User.find(p_to_r.user_id)
        if repository.platform.personal?
          platforms = Platform.availables_main_platforms(user)
        else
          platforms = [repository.platform]
        end
        platforms.each do |platform|
          platform.platform_arch_settings.by_default.pluck(:arch_id).each do |arch_id|
            build_list = p.build_lists.build do |bl|
              bl.save_to_platform       = repository.platform
              bl.build_for_platform     = platform
              bl.update_type            = 'newpackage'
              bl.arch_id                = arch_id
              bl.project_version        = p.project_version_for(platform, platform)
              bl.user                   = user
              bl.auto_publish_status    = p_to_r.auto_publish? ? BuildList::AUTO_PUBLISH_STATUS_DEFAULT : BuildList::AUTO_PUBLISH_STATUS_NONE
              bl.save_to_repository     = repository
              bl.include_repos          = [repository.id, platform.repositories.main.first.try(:id)].uniq.compact
            end
            build_list.save!
          end
        end
      end
    end
  end

  protected

  def increase_release_tag(project_version, user, message)
    blob = repo.tree(project_version).contents.find{ |n| n.is_a?(Grit::Blob) && n.name =~ /.spec$/ }
    return unless blob

    raw = Grit::GitRuby::Repository.new(repo.path).get_raw_object_by_sha1(blob.id)
    content = self.class.replace_release_tag raw.content
    return if content == raw.content

    update_file(blob.name, content.gsub("\r", ''),
      message: message,
      actor: user,
      head: project_version
    )
  end


  def create_archive(treeish, format)
    file_name = "#{name}-#{treeish}"
    fullname  = "#{file_name}.#{tag_file_format(format)}"
    file = Tempfile.new fullname,  File.join(Rails.root, 'tmp')
    system("cd #{path}; git archive --format=#{format == 'zip' ? 'zip' : 'tar'} --prefix=#{file_name}/ #{treeish} #{format == 'zip' ? '' : ' | gzip -9'} > #{file.path}")
    file.close
    {
      path:     file.path,
      fullname: fullname
    }
  end

  def tag_file_format(format)
    format == 'zip' ? 'zip' : 'tar.gz'
  end

  def truncate_name
    self.name = name.strip if name
  end

  def attach_to_personal_repository
    owner_repos = self.owner.personal_platform.repositories
    if is_package
      repositories << self.owner.personal_repository unless repositories.exists?(id: owner_repos.pluck(:id))
    else
      repositories.delete owner_repos
    end
  end

  def set_maintainer
    if maintainer_id.blank?
      self.maintainer_id = (owner_type == 'User') ? self.owner_id : self.owner.owner_id
    end
  end

  def set_new_git_head
    `cd #{path} && git symbolic-ref HEAD refs/heads/#{self.default_branch}` if self.default_branch_changed? && self.repo.branches.map(&:name).include?(self.default_branch)
  end

  def update_path_to_project(old_name)
    new_name, new_path = name, path
    self.name = old_name
    old_path  = path
    self.name = new_name
    FileUtils.mv old_path, new_path, force: true if Dir.exists?(old_path)

    pull_requests_old_path = File.join(APP_CONFIG['git_path'], 'pull_requests', owner.uname, old_name)
    if Dir.exists?(pull_requests_old_path)
      FileUtils.mv  pull_requests_old_path,
                    File.join(APP_CONFIG['git_path'], 'pull_requests', owner.uname, new_name),
                    force: true
    end

    PullRequest.where(from_project_id: id).update_all(from_project_name: new_name)

    PullRequest.where(from_project_id: id).each{ |p| p.update_relations(old_name) }
    pull_requests.where('from_project_id != to_project_id').each(&:update_relations)
  end
  later :update_path_to_project, queue: :clone_build

  def check_default_branch
    if self.repo.branches.count > 0 && self.repo.branches.map(&:name).exclude?(self.default_branch)
      errors.add :default_branch, I18n.t('activerecord.errors.project.default_branch')
    end
  end
end
