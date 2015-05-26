# Internal: various definitions and instance methods related to status.
#
# This module gets mixed in into ProductBuildList class.
module ProductBuildLists::Statusable
  extend ActiveSupport::Concern

  BUILD_COMPLETED            = 0
  BUILD_FAILED               = 1
  BUILD_PENDING              = 2
  BUILD_STARTED              = 3
  BUILD_CANCELED             = 4
  BUILD_CANCELING            = 5
  BUILD_COMPLETED_PARTIALLY  = 6

  STATUSES = [
    BUILD_STARTED,
    BUILD_COMPLETED,
    BUILD_COMPLETED_PARTIALLY,
    BUILD_FAILED,
    BUILD_PENDING,
    BUILD_CANCELED,
    BUILD_CANCELING
  ].freeze

  HUMAN_STATUSES = {
    BUILD_STARTED             => :build_started,
    BUILD_COMPLETED           => :build_completed,
    BUILD_COMPLETED_PARTIALLY => :build_completed_partially,
    BUILD_FAILED              => :build_failed,
    BUILD_PENDING             => :build_pending,
    BUILD_CANCELED            => :build_canceled,
    BUILD_CANCELING           => :build_canceling
  }.freeze


  included do

    scope :for_status, -> (status) { where(status: status) if status.present? }

    validates :status,
      presence:       true,
      inclusion:      { in: STATUSES }

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

      # build_canceling: :build_completed - Worker hasn't time to cancel building because build had been already completed
      event :build_success_partially do
        transition [:build_started, :build_canceling] => :build_completed_partially
      end

      # build_canceling: :build_failed - Worker hasn't time to cancel building because build had been already failed
      event :build_error do
        transition [:build_started, :build_canceling] => :build_failed
      end

      HUMAN_STATUSES.each do |code,name|
        state name, value: code
      end
    end

  end

  module ClassMethods
    def human_status(status)
      I18n.t("layout.product_build_lists.statuses.#{HUMAN_STATUSES[status]}")
    end
  end

  ######################################
  #          Instance methods          #
  ######################################

  def build_started?
    status == BUILD_STARTED
  end

  def build_canceling?
    status == BUILD_CANCELING
  end

  def can_destroy?
    [BUILD_STARTED, BUILD_PENDING, BUILD_CANCELING].exclude?(status)
  end

  def can_cancel?
    [BUILD_STARTED, BUILD_PENDING].include?(status)
  end

  def human_status
    self.class.human_status(status)
  end

end
