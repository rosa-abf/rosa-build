class ProductBuildList < ActiveRecord::Base
  include CommitAndVersion
  include TimeLiving
  include FileStoreClean
  include UrlHelper
  include AbfWorkerMethods
  include EventLoggable

  delegate :url_helpers, to: 'Rails.application.routes'

  LIVE_TIME     = 2.week  # for autostart
  MAX_LIVE_TIME = 3.month # for manual start;

  BUILD_COMPLETED       = 0
  BUILD_FAILED          = 1
  BUILD_PENDING         = 2
  BUILD_STARTED         = 3
  BUILD_CANCELED        = 4
  BUILD_CANCELING       = 5

  STATUSES = [  BUILD_STARTED,
                BUILD_COMPLETED,
                BUILD_FAILED,
                BUILD_PENDING,
                BUILD_CANCELED,
                BUILD_CANCELING
              ].freeze

  HUMAN_STATUSES = { BUILD_STARTED => :build_started,
                     BUILD_COMPLETED => :build_completed,
                     BUILD_FAILED => :build_failed,
                     BUILD_PENDING => :build_pending,
                     BUILD_CANCELED => :build_canceled,
                     BUILD_CANCELING => :build_canceling
                    }.freeze

  CACHED_CHROOT_TOKEN_DESCRIPTION = 'cached-chroot'

  belongs_to :product
  belongs_to :project
  belongs_to :arch
  belongs_to :user

  # see: Issue #6
  before_validation -> { self.arch_id = Arch.find_by(name: 'x86_64').id }, on: :create
  # field "not_delete" can be changed only if build has been completed
  before_validation -> { self.not_delete = false unless build_completed?; true }

  validates :product, :product_id,
            :status,
            :project, :project_id,
            :main_script,
            :arch,    :arch_id,
            presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :main_script, :params, length: { maximum: 255 }

  attr_accessor :base_url, :product_name
  attr_accessible :status,
                  :base_url,
                  :branch,
                  :project_id,
                  :main_script,
                  :params,
                  :project_version,
                  :commit_hash,
                  :product_id,
                  :not_delete,
                  :product_name

  attr_readonly :product_id
  serialize :results, Array


  scope :default_order,           -> { order(updated_at: :desc) }
  scope :for_status,              -> (status) { where(status: status) if status.present? }
  scope :for_user,                -> (user) { where(user_id: user.id) }
  scope :scoped_to_product_name,  -> (product_name) {
    joins(:product).where('products.name LIKE ?', "%#{product_name}%") if product_name.present?
  }
  scope :recent,                  -> { order(updated_at: :desc) }
  scope :outdated, -> {
    where(not_delete: false).
    where("(#{table_name}.created_at < ? AND #{table_name}.autostarted is TRUE) OR #{table_name}.created_at < ?",
          Time.now - LIVE_TIME, Time.now - MAX_LIVE_TIME)
  }

  after_initialize :init_project, if: :new_record?

  after_create :add_job_to_abf_worker_queue
  before_destroy :can_destroy?

  state_machine :status, initial: :build_pending do

    event :start_build do
      transition build_pending: :build_started
    end

    event :cancel do
      transition [:build_pending, :build_started] => :build_canceling
    end
    after_transition on: :cancel, do: :cancel_job

    # build_canceling: :build_canceled - canceling from UI
    # build_started: :build_canceled - canceling from worker by time-out (time_living has been expired)
    event :build_canceled do
      transition [:build_canceling, :build_started] => :build_canceled
    end

    # build_canceling: :build_completed - Worker hasn't time to cancel building because build had been already completed
    event :build_success do
      transition [:build_started, :build_canceling] => :build_completed
    end

    # build_canceling: :build_failed - Worker hasn't time to cancel building because build had been already failed
    event :build_error do
      transition [:build_started, :build_canceling] => :build_failed
    end

    HUMAN_STATUSES.each do |code,name|
      state name, value: code
    end
  end

  def build_started?
    status == BUILD_STARTED
  end

  def build_canceling?
    status == BUILD_CANCELING
  end

  def can_destroy?
    ![BUILD_STARTED, BUILD_PENDING, BUILD_CANCELING].include?(status)
  end

  def can_cancel?
    [BUILD_STARTED, BUILD_PENDING].include?(status)
  end

  def event_log_message
    {product: product.name}.inspect
  end

  def self.human_status(status)
    I18n.t("layout.product_build_lists.statuses.#{HUMAN_STATUSES[status]}")
  end

  def human_status
    self.class.human_status(status)
  end

  def can_destroy?
    [BUILD_COMPLETED, BUILD_FAILED, BUILD_CANCELED].include? status
  end

  def sha1_of_file_store_files
    (results || []).map{ |r| r['sha1'] }.compact
  end

  protected

  def init_project
    self.project ||= product.try(:project)
  end

  def abf_worker_priority
    ''
  end

  def abf_worker_base_queue
    'iso_worker'
  end

  def abf_worker_args
    file_name = "#{project.name}-#{commit_hash}"
    opts = default_url_options
    opts.merge!({user: user.authentication_token, password: ''}) if user.present?
    srcpath = url_helpers.archive_url(
      project.name_with_owner,
      file_name,
      'tar.gz',
      opts
    )

    cmd_params = "BUILD_ID=#{id} "
    if product.platform.hidden?
      token = product.platform.tokens.by_active.where(description: CACHED_CHROOT_TOKEN_DESCRIPTION).first
      cmd_params << "TOKEN=#{token.authentication_token} " if token
    end
    cmd_params << params.to_s

    {
      id: id,
      # TODO: remove comment
      # srcpath: 'http://dl.dropbox.com/u/945501/avokhmin-test-iso-script-5d9b463d4e9c06ea8e7c89e1b7ff5cb37e99e27f.tar.gz',
      srcpath:      srcpath,
      params:       cmd_params,
      time_living:  time_living,
      main_script:  main_script,
      platform: {
        type: product.platform.distrib_type,
        name: product.platform.name,
        arch: arch.name
      },
      user: {uname: user.try(:uname), email: user.try(:email)}
    }
  end
end
