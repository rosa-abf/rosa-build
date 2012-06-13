# -*- encoding : utf-8 -*-
class BuildList < ActiveRecord::Base
  belongs_to :project
  belongs_to :arch
  belongs_to :save_to_platform, :class_name => 'Platform'
  belongs_to :build_for_platform, :class_name => 'Platform'
  belongs_to :user
  belongs_to :advisory
  belongs_to :mass_build
  has_many :items, :class_name => "BuildList::Item", :dependent => :destroy
  has_many :packages, :class_name => "BuildList::Package", :dependent => :destroy

  UPDATE_TYPES = %w[security bugfix enhancement recommended newpackage]
  RELEASE_UPDATE_TYPES = %w[security bugfix]

  validates :project_id, :project_version, :arch, :include_repos, :presence => true
  validates_numericality_of :priority, :greater_than_or_equal_to => 0
  validates :update_type, :inclusion => UPDATE_TYPES,
            :unless => Proc.new { |b| b.save_to_platform.released }
  validates :update_type, :inclusion => {:in => RELEASE_UPDATE_TYPES, :message => I18n.t('flash.build_list.frozen_platform')},
            :if => Proc.new { |b| b.save_to_platform.released && b.mass_build_id.nil?}
  validate lambda {
    errors.add(:build_for_platform, I18n.t('flash.build_list.wrong_platform')) if save_to_platform.platform_type == 'main' && save_to_platform_id != build_for_platform_id
  }

  LIVE_TIME = 3.week

  # The kernel does not send these statuses directly
  BUILD_CANCELED = 5000
  WAITING_FOR_RESPONSE = 4000
  BUILD_PENDING = 2000
  BUILD_PUBLISHED = 6000
  BUILD_PUBLISH = 7000
  FAILED_PUBLISH = 8000
  REJECTED_PUBLISH = 9000

  STATUSES = [  WAITING_FOR_RESPONSE,
                BUILD_CANCELED,
                BUILD_PENDING,
                BUILD_PUBLISHED,
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
  scope :for_platform, lambda { |platform| where(:build_for_platform_id => platform.id)  }
  scope :by_mass_build, lambda { |mass_build| where(:mass_build_id => mass_build)  }
  scope :scoped_to_arch, lambda {|arch| where(:arch_id => arch) }
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
  scope :outdated, where('updated_at < ? AND status <> ?', Time.now - LIVE_TIME, BUILD_PUBLISHED)

  serialize :additional_repos
  serialize :include_repos

  after_create :place_build
  after_destroy :delete_container

  state_machine :status, :initial => :waiting_for_response do

    event :place_build do
      transition :waiting_for_response => :build_pending, :if => lambda { |build_list|
        build_list.add_to_queue == BUILD_PENDING
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

    event :start do
      transition [ :build_pending,
                   :platform_pending,
                   :platform_not_found,
                   :project_not_found,
                   :project_version_not_found ] => :build_started
    end

    event :cancel do
      transition [:build_pending, :platform_pending] => :build_canceled, :if => lambda { |build_list|
        has_canceled = BuildServer.delete_build_list build_list.bs_id
        build_list.can_cancel? && has_canceled == 0
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
        BuildServer.publish_container(build_list.bs_id) == 0
      }
      transition [:success, :failed_publish] => :failed_publish
    end

    event :reject_publish do
      transition :success => :rejected_publish, :if => :can_reject_publish?
    end

    event :success do
      transition [:build_started, :build_canceled] => :success
    end

    event :error do
      transition [:build_started, :build_canceled] => :build_error
    end

    HUMAN_STATUSES.each do |code,name|
      state name, :value => code
    end

  end

  #TODO: Share this checking on product owner.
  def can_cancel?
    status == BUILD_PENDING && bs_id
  end

  def can_reject_publish?
    can_publish? and save_to_platform.released
  end


  def add_to_queue
    #XML-RPC params: project_name, project_version, plname, arch, bplname, update_type, build_requires, id_web, include_repos, priority
    @status ||= BuildServer.add_build_list project.name, project_version, save_to_platform.name, arch.name, (save_to_platform_id == build_for_platform_id ? '' : build_for_platform.name), update_type, build_requires, id, include_repos, priority
  end

  def self.human_status(status)
    I18n.t("layout.build_lists.statuses.#{HUMAN_STATUSES[status]}")
  end

  def human_status
    self.class.human_status(status)
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
    I18n.t("layout.build_lists.human_duration", {:hours => (duration/3600).to_i, :minutes => (duration%3600/60).to_i})
  end

  def in_work?
    status == BuildServer::BUILD_STARTED 
    #[WAITING_FOR_RESPONSE, BuildServer::BUILD_PENDING, BuildServer::BUILD_STARTED].include?(status)
  end

  protected

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
end
