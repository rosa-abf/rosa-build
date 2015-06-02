class RepositoryStatus < ActiveRecord::Base
  include FileStoreClean
  include RegenerationStatus

  WAITING_FOR_RESIGN        = 300
  PUBLISH                   = 400
  RESIGN                    = 500
  WAITING_FOR_RESIGN_AFTER_PUBLISH        = 600
  WAITING_FOR_RESIGN_AFTER_REGENERATION   = 700
  WAITING_FOR_REGENERATION_AFTER_PUBLISH  = 800
  WAITING_FOR_REGENERATION_AFTER_RESIGN   = 900
  WAITING_FOR_RESIGN_AND_REGENERATION_AFTER_PUBLISH   = 1000
  WAITING_FOR_RESIGN_AND_REGENERATION     = 1100


  HUMAN_STATUSES = HUMAN_STATUSES.clone.merge({
    WAITING_FOR_RESIGN        => :waiting_for_resign,
    PUBLISH                   => :publish,
    RESIGN                    => :resign,
    WAITING_FOR_RESIGN_AFTER_PUBLISH        => :waiting_for_resign_after_publish,
    WAITING_FOR_RESIGN_AFTER_REGENERATION   => :waiting_for_resign_after_regeneration,
    WAITING_FOR_REGENERATION_AFTER_PUBLISH  => :waiting_for_regeneration_after_publish,
    WAITING_FOR_REGENERATION_AFTER_RESIGN   => :waiting_for_regeneration_after_resign,
    WAITING_FOR_RESIGN_AND_REGENERATION_AFTER_PUBLISH   => :waiting_for_resign_and_regeneration_after_publish,
    WAITING_FOR_RESIGN_AND_REGENERATION     => :waiting_for_resign_and_regeneration
  }).freeze

  belongs_to :platform
  belongs_to :repository

  validates :repository, :platform, presence: true
  validates :repository_id, uniqueness: { scope: :platform_id }

  scope :platform_ready, -> { where(platforms: {status: READY}).joins(:platform) }
  scope :for_regeneration, -> { where(status: WAITING_FOR_REGENERATION) }
  scope :for_resign, -> { where(status: [WAITING_FOR_RESIGN, WAITING_FOR_RESIGN_AND_REGENERATION]) }
  scope :not_ready, -> { where('repository_statuses.status != ?', READY) }

  state_machine :status, initial: :ready do
    event :ready do
      transition [:regenerating, :publish, :resign] => :ready
      transition [:waiting_for_resign_after_publish, :waiting_for_resign_after_regeneration] => :waiting_for_resign
      transition [:waiting_for_regeneration_after_publish, :waiting_for_regeneration_after_resign] => :waiting_for_regeneration
      transition waiting_for_resign_and_regeneration_after_publish: :waiting_for_resign_and_regeneration
    end

    event :regenerate do
      transition ready: :waiting_for_regeneration
      transition publish: :waiting_for_regeneration_after_publish
      transition resign: :waiting_for_regeneration_after_resign
      transition waiting_for_resign_after_publish: :waiting_for_resign_and_regeneration_after_publish
      transition waiting_for_resign: :waiting_for_resign_and_regeneration
    end

    event :start_regeneration do
      transition waiting_for_regeneration: :regenerating
      transition waiting_for_resign_and_regeneration: :waiting_for_resign_after_regeneration
    end

    event :resign do
      transition ready: :waiting_for_resign
      transition publish: :waiting_for_resign_after_publish
      transition waiting_for_regeneration: :waiting_for_resign_and_regeneration
      transition waiting_for_regeneration_after_publish: :waiting_for_resign_and_regeneration_after_publish
      transition regenerating: :waiting_for_resign_after_regeneration
    end

    event :start_resign do
      transition waiting_for_resign: :resign
      transition waiting_for_resign_and_regeneration: :waiting_for_regeneration_after_resign
    end

    event :publish do
      transition ready: :publish
    end

    HUMAN_STATUSES.each do |code,name|
      state name, value: code
    end
  end
end
