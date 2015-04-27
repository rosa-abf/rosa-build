class Project < ActiveRecord::Base
  has_ancestry orphan_strategy: :adopt # we replace a 'path' method in the Git module

  include Autostart
  include Owner
  include Git
  include Wiki
  include UrlHelper
  include EventLoggable
  include Project::DefaultBranch
  include Project::Finders

  VISIBILITIES = ['open', 'hidden']
  MAX_OWN_PROJECTS = 32000
  NAME_REGEXP = /[\w\-\+\.]+/
  OWNER_AND_NAME_REGEXP = /#{User::NAME_REGEXP.source}\/#{NAME_REGEXP.source}/
  self.per_page = 25

  belongs_to :owner, polymorphic: true, counter_cache: :own_projects_count
  belongs_to :maintainer, class_name: 'User'

  belongs_to :alias_from, class_name: 'Project'
  has_many   :aliases,    class_name: 'Project', foreign_key: 'alias_from_id'

  has_many :issues,         dependent: :destroy
  has_many :pull_requests,  dependent: :destroy, foreign_key: 'to_project_id'
  has_many :labels,         dependent: :destroy
  has_many :build_scripts,  dependent: :destroy

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
                   format: { with: /\A#{NAME_REGEXP.source}\z/,
                             message: I18n.t("activerecord.errors.project.uname") },
                   length: { maximum: 100 }
  validates :maintainer, presence: true, unless: :new_record?
  validates :url, presence: true, format: { with: /\Ahttps?:\/\/[\S]+\z/ }, if: :mass_import
  validates :add_to_repository_id, presence: true, if: :mass_import
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validate { errors.add(:base, :can_have_less_or_equal, count: MAX_OWN_PROJECTS) if owner.projects.size >= MAX_OWN_PROJECTS }
  # throws validation error message from ProjectToRepository model into Project model
  validate do |project|
    project.project_to_repositories.each do |p_to_r|
      next if p_to_r.valid?
      p_to_r.errors.full_messages.each{ |msg| errors[:base] << msg }
    end
    errors.delete :project_to_repositories
  end

  # attr_accessible :name, :description, :visibility, :srpm, :is_package,
  #                 :has_issues, :has_wiki, :maintainer_id, :publish_i686_into_x86_64,
  #                 :url, :srpms_list, :mass_import, :add_to_repository_id, :architecture_dependent,
  #                 :autostart_status
  attr_readonly :owner_id, :owner_type

  before_validation :truncate_name, on: :create
  before_save -> { self.owner_uname = owner.uname if owner_uname.blank? || owner_id_changed? || owner_type_changed? }
  before_create :set_maintainer
  after_save :attach_to_personal_repository
  after_update -> { update_path_to_project(name_was) }, if: :name_changed?

  attr_accessor :url, :srpms_list, :mass_import, :add_to_repository_id

  def init_mass_import
    Project.perform_later :low, :run_mass_import, url, srpms_list, visibility, owner, add_to_repository_id
  end

  def name_with_owner
    "#{owner_uname || owner.uname}/#{name}"
  end

  def to_param
    name_with_owner
  end

  def all_members(*includes)
    members(includes) | (owner_type == 'User' ? [owner] : owner.members.includes(includes))
  end

  def members(*includes)
    collaborators.includes(includes) | groups.map{ |g| g.members.includes(includes) }.flatten
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
    Rails.application.routes.url_helpers.project_url(self.name_with_owner, opts) + '.git'
    #path #share by NFS
  end

  def build_for(mass_build, repository_id, arch =  Arch.find_by(name: 'i586'), priority = 0, increase_rt = false)
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
      bl.save_to_platform               = save_to_platform
      bl.build_for_platform             = build_for_platform
      bl.update_type                    = 'newpackage'
      bl.arch                           = arch
      bl.project_version                = project_version
      bl.user                           = user
      bl.auto_publish_status            = mass_build.auto_publish_status
      bl.auto_create_container          = mass_build.auto_create_container
      bl.include_repos                  = include_repos
      bl.extra_repositories             = mass_build.extra_repositories
      bl.extra_build_lists              = mass_build.extra_build_lists
      bl.priority                       = priority
      bl.mass_build_id                  = mass_build.id
      bl.save_to_repository_id          = repository_id
      bl.include_testing_subrepository  = mass_build.include_testing_subrepository?
      bl.use_cached_chroot              = mass_build.use_cached_chroot?
      bl.use_extra_tests                = mass_build.use_extra_tests?
      bl.external_nodes                 = mass_build.external_nodes
    end
    build_list.save
  end

  def fork(new_owner, new_name: nil, is_alias: false)
    new_name = new_name.presence || name
    dup.tap do |c|
      c.name          = new_name
      c.parent_id     = id
      c.alias_from_id = is_alias ? (alias_from_id || id) : nil
      c.owner         = new_owner
      c.updated_at    = nil; c.created_at = nil # :id = nil
      # Hack to call protected method :)
      c.send :set_maintainer
      c.save
    end
  end

  def get_project_tag_sha1(tag, format)
    format_id = ProjectTag::FORMATS["#{tag_file_format(format)}"]
    project_tag = project_tags.where(tag_name: tag.name, format_id: format_id).first

    return project_tag.sha1 if project_tag && project_tag.commit_id == tag.commit.id && FileStoreService::File.new(sha1: project_tag.sha1).exist?

    archive = archive_by_treeish_and_format tag.name, format
    sha1    = FileStoreService::File.new(data: archive).save
    return nil if sha1.blank?

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
              bl.update_type            = BuildList::UPDATE_TYPE_NEWPACKAGE
              bl.arch_id                = arch_id
              bl.project_version        = p.project_version_for(repository.platform, platform)
              bl.user                   = user
              bl.auto_publish_status    = p_to_r.auto_publish? ? BuildList::AUTO_PUBLISH_STATUS_DEFAULT : BuildList::AUTO_PUBLISH_STATUS_NONE
              bl.save_to_repository     = repository
              bl.include_repos          = [platform.repositories.main.first.try(:id)].compact
              if repository.platform.personal?
                bl.extra_repositories   = [repository.id]
              else
                bl.include_repos       |= [repository.id]
              end
            end
            build_list.save
          end
        end
      end
    end
  end

  def increase_release_tag(project_version, user, message)
    blob, raw = find_blob_and_raw_of_spec_file(project_version)
    return unless blob

    content = self.class.replace_release_tag raw.content
    return if content == raw.content

    update_file(blob.name, content.gsub("\r", ''),
      message: message,
      actor: user,
      head: project_version
    )
  end

  protected

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
  later :update_path_to_project, queue: :middle

end
