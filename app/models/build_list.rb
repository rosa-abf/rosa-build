# -*- encoding : utf-8 -*-
class BuildList < ActiveRecord::Base
  include Modules::Models::CommitAndVersion
  include AbfWorker::ModelHelper

  belongs_to :project
  belongs_to :arch
  belongs_to :save_to_platform, :class_name => 'Platform'
  belongs_to :save_to_repository, :class_name => 'Repository'
  belongs_to :build_for_platform, :class_name => 'Platform'
  belongs_to :user
  belongs_to :advisory
  belongs_to :mass_build, :counter_cache => true
  has_many :items, :class_name => "BuildList::Item", :dependent => :destroy
  has_many :packages, :class_name => "BuildList::Package", :dependent => :destroy

  UPDATE_TYPES = %w[security bugfix enhancement recommended newpackage]
  RELEASE_UPDATE_TYPES = %w[security bugfix]

  validates :project_id, :project_version, :arch, :include_repos,
            :build_for_platform_id, :save_to_platform_id, :save_to_repository_id, :presence => true
  validates_numericality_of :priority, :greater_than_or_equal_to => 0
  validates :update_type, :inclusion => UPDATE_TYPES,
            :unless => Proc.new { |b| b.advisory.present? }
  validates :update_type, :inclusion => {:in => RELEASE_UPDATE_TYPES, :message => I18n.t('flash.build_list.frozen_platform')},
            :if => Proc.new { |b| b.advisory.present? }
  validate lambda {
    errors.add(:build_for_platform, I18n.t('flash.build_list.wrong_platform')) if save_to_platform.platform_type == 'main' && save_to_platform_id != build_for_platform_id
  }
  validate lambda {
    errors.add(:build_for_platform, I18n.t('flash.build_list.wrong_build_for_platform')) unless build_for_platform.platform_type == 'main'
  }
  validate lambda {
    errors.add(:save_to_repository, I18n.t('flash.build_list.wrong_repository')) unless save_to_repository_id.in? save_to_platform.repositories.map(&:id)
  }
  validate lambda {
    include_repos.each {|ir|
      errors.add(:save_to_repository, I18n.t('flash.build_list.wrong_include_repos')) unless build_for_platform.repository_ids.include? ir.to_i
    }
  }

  LIVE_TIME = 4.week # for unpublished
  MAX_LIVE_TIME = 3.month # for published

  # The kernel does not send these statuses directly
  BUILD_CANCELED = 5000
  WAITING_FOR_RESPONSE = 4000
  BUILD_PENDING = 2000
  BUILD_PUBLISHED = 6000
  BUILD_PUBLISH = 7000
  FAILED_PUBLISH = 8000
  REJECTED_PUBLISH = 9000
  BUILD_CANCELING = 10000

  STATUSES = [  WAITING_FOR_RESPONSE,
                BUILD_CANCELED,
                BUILD_PENDING,
                BUILD_PUBLISHED,
                BUILD_CANCELING,
                BUILD_PUBLISH,
                FAILED_PUBLISH,
                REJECTED_PUBLISH,
                BuildServer::SUCCESS,
                BuildServer::BUILD_STARTED,
                BuildServer::BUILD_ERROR,
                BuildServer::PLATFORM_NOT_FOUND,
                BuildServer::PLATFORM_PENDING,
                BuildServer::PROJECT_NOT_FOUND,
                BuildServer::PROJECT_VERSION_NOT_FOUND,
                # BuildServer::BINARY_TEST_FAILED,
                # BuildServer::DEPENDENCY_TEST_FAILED
              ]

  HUMAN_STATUSES = { WAITING_FOR_RESPONSE => :waiting_for_response,
                     BUILD_CANCELED => :build_canceled,
                     BUILD_CANCELING => :build_canceling,
                     BUILD_PENDING => :build_pending,
                     BUILD_PUBLISHED => :build_published,
                     BUILD_PUBLISH => :build_publish,
                     FAILED_PUBLISH => :failed_publish,
                     REJECTED_PUBLISH => :rejected_publish,
                     BuildServer::BUILD_ERROR => :build_error,
                     BuildServer::BUILD_STARTED => :build_started,
                     BuildServer::SUCCESS => :success,
                     BuildServer::PLATFORM_NOT_FOUND => :platform_not_found,
                     BuildServer::PLATFORM_PENDING => :platform_pending,
                     BuildServer::PROJECT_NOT_FOUND => :project_not_found,
                     BuildServer::PROJECT_VERSION_NOT_FOUND => :project_version_not_found,
                     # BuildServer::DEPENDENCY_TEST_FAILED => :dependency_test_failed,
                     # BuildServer::BINARY_TEST_FAILED => :binary_test_failed
                    }

  scope :recent, order("#{table_name}.updated_at DESC")
  scope :for_status, lambda {|status| where(:status => status) }
  scope :for_user, lambda { |user| where(:user_id => user.id)  }
  scope :for_platform, lambda { |platform| where(:build_for_platform_id => platform)  }
  scope :by_mass_build, lambda { |mass_build| where(:mass_build_id => mass_build)  }
  scope :scoped_to_arch, lambda {|arch| where(:arch_id => arch) }
  scope :scoped_to_save_platform, lambda {|pl_id| where(:save_to_platform_id => pl_id) }
  scope :scoped_to_project_version, lambda {|project_version| where(:project_version => project_version) }
  scope :scoped_to_is_circle, lambda {|is_circle| where(:is_circle => is_circle) }
  scope :for_creation_date_period, lambda{|start_date, end_date|
    s = scoped
    s = s.where(["build_lists.created_at >= ?", start_date]) if start_date
    s = s.where(["build_lists.created_at <= ?", end_date]) if end_date
    s
  }
  scope :for_notified_date_period, lambda{|start_date, end_date|
    s = scoped
    s = s.where(["build_lists.updated_at >= ?", start_date]) if start_date
    s = s.where(["build_lists.updated_at <= ?", end_date]) if end_date
    s
  }
  scope :scoped_to_project_name, lambda {|project_name| joins(:project).where('projects.name LIKE ?', "%#{project_name}%")}
  scope :outdated, where('created_at < ? AND status <> ? OR created_at < ?', Time.now - LIVE_TIME, BUILD_PUBLISHED, Time.now - MAX_LIVE_TIME)

  serialize :additional_repos
  serialize :include_repos
  serialize :results, Array

  after_commit :place_build
  after_destroy :delete_container

  @queue = :clone_and_build

  state_machine :status, :initial => :waiting_for_response do

    # WTF? around_transition -> infinite loop
    before_transition do |build_list, transition|
      status = BuildList::HUMAN_STATUSES[build_list.status]
      if build_list.mass_build && MassBuild::COUNT_STATUSES.include?(status)
        MassBuild.decrement_counter "#{status.to_s}_count", build_list.mass_build_id
      end
    end

    after_transition do |build_list, transition|
      status = BuildList::HUMAN_STATUSES[build_list.status]
      if build_list.mass_build && MassBuild::COUNT_STATUSES.include?(status)
        MassBuild.increment_counter "#{status.to_s}_count", build_list.mass_build_id
      end
    end

    after_transition :on => :published, :do => [:set_version_and_tag, :actualize_packages]
    after_transition :on => :cancel, :do => [:cancel_job],
      :if => lambda { |build_list| build_list.build_canceling? }

    after_transition :on => [:published, :fail_publish, :build_error], :do => :notify_users
    after_transition :on => :build_success, :do => :notify_users,
      :unless => lambda { |build_list| build_list.auto_publish? }

    event :place_build do
      transition :waiting_for_response => :build_pending, :if => lambda { |build_list|
        build_list.add_to_queue == BuildServer::SUCCESS
      }
      [
        'BuildList::BUILD_PENDING',
        'BuildServer::PLATFORM_PENDING',
        'BuildServer::PLATFORM_NOT_FOUND',
        'BuildServer::PROJECT_NOT_FOUND',
        'BuildServer::PROJECT_VERSION_NOT_FOUND'
      ].each do |code|
        transition :waiting_for_response => code.demodulize.downcase.to_sym, :if => lambda { |build_list|
          build_list.add_to_queue == code.constantize
        }
      end
    end

    event :start_build do
      transition [ :build_pending,
                   :platform_pending,
                   :platform_not_found,
                   :project_not_found,
                   :project_version_not_found ] => :build_started
    end

    event :cancel do
      transition [:build_pending, :platform_pending] => :build_canceled, :if => lambda { |build_list|
        !build_list.new_core? && build_list.can_cancel? && BuildServer.delete_build_list(build_list.bs_id) == BuildServer::SUCCESS
      }
      transition [:build_pending, :build_started] => :build_canceling, :if => lambda { |build_list|
        build_list.new_core? && build_list.can_cancel?
      }
    end

    event :build_canceled do
      transition [:build_canceling] => :build_canceled, :if => lambda { |build_list|
        build_list.new_core?
      }
    end

    event :published do
      transition [:build_publish, :rejected_publish] => :build_published
    end

    event :fail_publish do
      transition [:build_publish, :rejected_publish] => :failed_publish
    end

    event :publish do
      transition [:success, :failed_publish] => :build_publish, :if => lambda { |build_list|
        BuildServer.publish_container(build_list.bs_id) == BuildServer::SUCCESS
      }
      transition [:success, :failed_publish] => :failed_publish
    end

    event :reject_publish do
      transition :success => :rejected_publish, :if => :can_reject_publish?
    end

    event :build_success do
      transition [:build_started, :build_canceled] => :success
    end

    event :build_error do
      transition [:build_started, :build_canceled, :build_canceling] => :build_error
    end

    HUMAN_STATUSES.each do |code,name|
      state name, :value => code
    end
  end

  later :publish, :queue => :clone_build

  def set_version_and_tag
    pkg = self.packages.where(:package_type => 'source', :project_id => self.project_id).first
    # TODO: remove 'return' after deployment ABF kernel 2.0
    return if pkg.nil? # For old client that does not sends data about packages
    self.package_version = "#{pkg.platform.name}-#{pkg.version}-#{pkg.release}"
    system("cd #{self.project.repo.path} && git tag #{self.package_version} #{self.commit_hash}") # TODO REDO through grit
    save
  end

  def actualize_packages
    ActiveRecord::Base.transaction do
      # packages from previous build_list
      self.last_published.limit(2).last.packages.update_all :actual => false
      self.packages.update_all :actual => true
    end
  end

  #TODO: Share this checking on product owner.
  def can_cancel?
    if new_core?
      build_started? || build_pending?
    else
      [BUILD_PENDING, BuildServer::PLATFORM_PENDING].include?(status) && bs_id
    end
  end

  def can_publish?
    [BuildServer::SUCCESS, FAILED_PUBLISH].include? status
  end

  def can_reject_publish?
    can_publish? and not save_to_repository.publish_without_qa
  end

  def add_to_queue
    if new_core?
      add_job_to_abf_worker_queue unless @status
      @status ||= BUILD_PENDING
    else
      # XML-RPC params:
      # - project_name
      # - project_version
      # - plname
      # - arch
      # - bplname
      # - update_type
      # - build_requires
      # - id_web
      # - include_repos
      # - priority
      # - git_project_address
      @status ||= BuildServer.add_build_list(
        project.name,
        project_version,
        save_to_platform.name,
        arch.name,
        (save_to_platform_id == build_for_platform_id ? '' : build_for_platform.name),
        update_type,
        build_requires,
        id,
        include_repos,
        priority,
        project.git_project_address
      )
    end
    @status
  end

  def self.human_status(status)
    I18n.t("layout.build_lists.statuses.#{HUMAN_STATUSES[status]}")
  end

  def human_status
    self.class.human_status(status)
  end

  def self.status_by_human(human)
    BuildList::HUMAN_STATUSES.key human
  end

  def set_items(items_hash)
    self.items = []

    items_hash.each do |level, items|
      items.each do |item|
        self.items << self.items.build(:name => item['name'], :version => item['version'], :level => level.to_i)
      end
    end
  end

  def set_packages(pkg_hash, project_name)
    prj = Project.joins(:repositories => :platform).where('platforms.id = ?', save_to_platform.id).find_by_name!(project_name)
    build_package(pkg_hash['srpm'], 'source', prj) {|p| p.save!}
    pkg_hash['rpm'].each do |rpm_hash|
      build_package(rpm_hash, 'binary', prj) {|p| p.save!}
    end
  end

  def event_log_message
    {:project => project.name, :version => project_version, :arch => arch.name}.inspect
  end

  def current_duration
    (Time.now.utc - started_at.utc).to_i
  end

  def human_current_duration
    I18n.t("layout.build_lists.human_current_duration", {:hours => (current_duration/3600).to_i, :minutes => (current_duration%3600/60).to_i})
  end

  def human_duration
    duration ||= current_duration
    I18n.t("layout.build_lists.human_duration", {:hours => (duration/3600).to_i, :minutes => (duration%3600/60).to_i})
  end

  def fs_log_path(log_type = :build)
    container_path? ? "downloads/#{container_path}/log/#{project.name}/#{log_type.to_s}.log" : nil
  end

  def in_work?
    status == BuildServer::BUILD_STARTED
    #[WAITING_FOR_RESPONSE, BuildServer::BUILD_PENDING, BuildServer::BUILD_STARTED].include?(status)
  end

  def associate_and_create_advisory(params)
    build_advisory(params){ |a| a.update_type = update_type }
    advisory.attach_build_list(self)
  end

  def can_attach_to_advisory?
    !save_to_repository.publish_without_qa &&
      save_to_platform.main? &&
      save_to_platform.released &&
      build_published?
  end

  def log(load_lines)
    if new_core?
      abf_worker_log
    else
      log = `tail -n #{load_lines.to_i} #{Rails.root + 'public' + fs_log_path}`
      $?.success? ? log : I18n.t('layout.build_lists.log.not_available')
    end
  end

  protected

  def abf_worker_args
    include_repos_hash = {}.tap do |h|
      include_repos.each do |r|
        repo = Repository.find r
        path = repo.platform.public_downloads_url(nil, arch.name, repo.name)
        # path = path.gsub(/^http:\/\/0\.0\.0\.0\:3000/, 'https://abf.rosalinux.ru')
        # Path looks like:
        # http://abf.rosalinux.ru/downloads/rosa-server2012/repository/x86_64/base/
        # so, we should append:
        # /release
        # /updates
        h["#{repo.name}_release"] = path + 'release'
        h["#{repo.name}_updates"] = path + 'updates'
      end
    end
    # mdv example:
    # https://abf.rosalinux.ru/import/plasma-applet-stackfolder.git
    # bfe6d68cc607238011a6108014bdcfe86c69456a

    # rhel example:
    # https://abf.rosalinux.ru/server/gnome-settings-daemon.git
    # fbb2549e44d97226fea6748a4f95d1d82ffb8726

    {
      :id => id,
      :arch => arch.name,
      :time_living => 2880, # 2 days
      :distrib_type => build_for_platform.distrib_type,
      # :git_project_address => 'https://abf.rosalinux.ru/server/gnome-settings-daemon.git',
      :git_project_address => project.git_project_address,
      # :commit_hash => 'fbb2549e44d97226fea6748a4f95d1d82ffb8726',
      :commit_hash => commit_hash,
      :build_requires => build_requires,
      :include_repos => include_repos_hash,
      :bplname => build_for_platform.name,
      :user => {:uname => user.uname, :email => user.email}
    }
  end

  def notify_users
    unless mass_build_id
      users = []
      if project # find associated users
        users = project.all_members.
          select{ |user| user.notifier.can_notify? && user.notifier.new_associated_build? }
      end
      if user.notifier.can_notify? && user.notifier.new_build?
        users = users | [user]
      end
      users.each do |user|
        UserMailer.build_list_notification(self, user).deliver
      end
    end
  end # notify_users

  def delete_container
    if can_cancel?
      BuildServer.delete_build_list bs_id
    else
      BuildServer.delete_container bs_id if bs_id # prevent error if bs_id does not set
    end
  end

  def build_package(pkg_hash, package_type, prj)
    packages.create(pkg_hash) do |p|
      p.project = prj
      p.platform = save_to_platform
      p.package_type = package_type
      yield p
    end
  end

  def last_published
    BuildList.where(:project_id => self.project_id,
                    :save_to_repository_id => self.save_to_repository_id)
             .for_platform(self.build_for_platform_id)
             .scoped_to_arch(self.arch_id)
             .for_status(BUILD_PUBLISHED)
             .recent
  end
end
