class Issue < ActiveRecord::Base
  include Feed::Issue

  STATUSES = [
    STATUS_OPEN   = 'open',
    STATUS_REOPEN = 'reopen',
    STATUS_CLOSED = 'closed'
  ]
  HASH_TAG_REGEXP = /([a-zA-Z0-9\-_]*\/)?([a-zA-Z0-9\-_]*)?#([0-9]+)/
  self.per_page   = 20

  belongs_to :project
  belongs_to :user
  belongs_to :assignee,
              class_name:   'User',
              foreign_key:  'assignee_id'

  belongs_to :closer,
              class_name:   'User',
              foreign_key:  'closed_by'

  has_many :comments,
            as:         :commentable,
            dependent:  :destroy

  has_many :subscribes,
            as:         :subscribeable,
            dependent:  :destroy

  has_many :labelings,
            dependent:  :destroy

  has_many :labels,
            -> { uniq },
            through:    :labelings

  has_one :pull_request#, dependent: :destroy

  validates :title, :body, :project, presence: true
  validates :title, length: { maximum: 100 }
  validates :body, length: { maximum: 10000 }

  after_create :set_serial_id
  after_create :subscribe_users
  after_update :subscribe_issue_assigned_user

  before_create :update_statistic
  before_update :update_statistic

  # attr_accessible :labelings_attributes, :title, :body, :assignee_id
  accepts_nested_attributes_for :labelings,
    reject_if:     -> (attributes) { attributes['label_id'].blank? },
    allow_destroy: true

  scope :opened, -> { where(status: [STATUS_OPEN, STATUS_REOPEN]) }
  scope :closed, -> { where(status: STATUS_CLOSED) }

  scope :needed_checking,       -> { where(issues: { status: %w(open reopen blocked ready already) }) }
  scope :not_closed_or_merged,  -> { needed_checking }
  scope :closed_or_merged,      -> { where(issues: { status: %w(closed merged) }) }
  # Using mb_chars for correct transform to lowercase ('Русский Текст'.downcase => "Русский Текст")
  scope :search,                ->(q) {
    where("#{table_name}.title ILIKE ?", "%#{q.mb_chars.downcase}%") if q.present?
  }
  scope :without_pull_requests, -> {
    where('NOT EXISTS (select null from pull_requests as pr where pr.issue_id = issues.id)').
    references(:pull_requests)
  }

  attr_accessor :new_pull_request

  def assign_uname
    assignee.uname if assignee
  end

  def to_param
    serial_id.to_s
  end

  def subscribe_creator(creator_id)
    unless self.subscribes.exists?(user_id: creator_id)
      self.subscribes.create(user_id: creator_id)
    end
  end

  def closed?
    closed_by && closed_at && status == STATUS_CLOSED
  end

  def set_close(closed_by)
    self.closed_at  = Time.now.utc
    self.closer     = closed_by
    self.status     = STATUS_CLOSED
  end

  def set_open
    self.closed_at  = self.closed_by = nil
    self.status     = STATUS_REOPEN
  end

  def collect_recipients
    recipients = self.project.all_members
    recipients = recipients | [self.assignee] if self.assignee
    recipients
  end

  def self.find_by_hash_tag(hash_tag, current_user, project)
    hash_tag =~ HASH_TAG_REGEXP
    owner_uname   = Regexp.last_match[1].presence || Regexp.last_match[2].presence || project.owner.uname
    project_name  = Regexp.last_match[1] ? Regexp.last_match[2] : project.name
    serial_id     = Regexp.last_match[3]
    project       = Project.find_by_owner_and_name(owner_uname.chomp('/'), project_name)
    return nil unless project
    return nil unless ProjectPolicy.new(current_user, project).show?
    project.issues.where(serial_id: serial_id).first
  end

  protected

  def update_statistic
    key = (pull_request || new_pull_request) ? Statistic::KEY_PULL_REQUEST : Statistic::KEY_ISSUE
    Statistic.statsd_increment(
      activity_at:  Time.now,
      key:          "#{key}.#{status}",
      project_id:   project_id,
      user_id:      closed_by || user_id,
    ) if new_record? || status_changed?
  end

  def set_serial_id
    self.serial_id = self.project.issues.count
    self.save!
  end

  def subscribe_users
    collect_recipients.each do |recipient|
      if recipient.notifier.new_comment && !self.subscribes.exists?(user_id: recipient.id)
        ss = self.subscribes.create(user_id: recipient.id)
      end
    end
  end

  def subscribe_issue_assigned_user
    if self.assignee_id && self.assignee_id_changed?
      self.subscribes.where(user_id: self.assignee_id_was).first.try(:destroy) unless self.assignee_id_was.blank?
      if self.assignee.notifier.issue_assign && !self.subscribes.exists?(user_id: self.assignee_id)
        self.subscribes.create(user_id: self.assignee_id)
      end
    end
  end
end
