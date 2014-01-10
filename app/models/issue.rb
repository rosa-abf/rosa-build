class Issue < ActiveRecord::Base
  include Modules::Observers::ActivityFeed::Issue
  STATUSES = ['open', 'closed']

  belongs_to :project
  belongs_to :user
  belongs_to :assignee, :class_name => 'User', :foreign_key => 'assignee_id'
  belongs_to :closer, :class_name => 'User', :foreign_key => 'closed_by'

  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :subscribes, :as => :subscribeable, :dependent => :destroy
  has_many :labelings, :dependent => :destroy
  has_many :labels, :through => :labelings, :uniq => true
  has_one :pull_request, :dependent => :destroy

  validates :title, :body, :project_id, :presence => true

  after_create :set_serial_id
  after_create :subscribe_users
  after_update :subscribe_issue_assigned_user

  attr_accessible :labelings_attributes, :title, :body, :assignee_id
  accepts_nested_attributes_for :labelings, :allow_destroy => true

  scope :opened, where(:status => 'open')
  scope :closed, where(:status => 'closed')

  scope :needed_checking, where(:issues => {:status => ['open', 'blocked', 'ready', 'already']})
  scope :not_closed_or_merged, needed_checking
  scope :closed_or_merged, where(:issues => {:status => ['closed', 'merged']})
  # Using mb_chars for correct transform to lowercase ('Русский Текст'.downcase => "Русский Текст")
  scope :search, lambda {|q| where("#{table_name}.title ILIKE ?", "%#{q.mb_chars.downcase}%") if q.present?}
  scope :without_pull_requests, where('NOT EXISTS (select null from pull_requests as pr where pr.issue_id = issues.id)')

  def assign_uname
    assignee.uname if assignee
  end

  def to_param
    serial_id.to_s
  end

  def subscribe_creator(creator_id)
    if !self.subscribes.exists?(:user_id => creator_id)
      self.subscribes.create(:user_id => creator_id)
    end
  end

  def closed?
    closed_by && closed_at && status == 'closed'
  end

  def set_close(closed_by)
    self.closed_at = Time.now.utc
    self.closer = closed_by
    self.status = 'closed'
  end

  def set_open
    self.closed_at = self.closed_by = nil
    self.status = 'open'
  end

  def collect_recipients
    recipients = self.project.admins
    recipients = recipients | [self.assignee] if self.assignee
    recipients
  end

  def self.find_by_hash_tag hash_tag, current_ability, project
    hash_tag =~ /([a-zA-Z0-9\-_]*\/)?([a-zA-Z0-9\-_]*)?#([0-9]+)/
    owner_uname = Regexp.last_match[1].presence || Regexp.last_match[2].presence || project.owner.uname
    project_name = Regexp.last_match[1] ? Regexp.last_match[2] : project.name
    serial_id = Regexp.last_match[3]
    project = Project.find_by_owner_and_name(owner_uname.chomp('/'), project_name)
    return nil unless project
    return nil unless current_ability.can? :show, project
    project.issues.where(:serial_id => serial_id).first
  end

  protected

  def set_serial_id
    self.serial_id = self.project.issues.count
    self.save!
  end

  def subscribe_users
    collect_recipients.each do |recipient|
      if recipient.notifier.new_comment && !self.subscribes.exists?(:user_id => recipient.id)
        ss = self.subscribes.create(:user_id => recipient.id)
      end
    end
  end

  def subscribe_issue_assigned_user
    if self.assignee_id && self.assignee_id_changed?
      self.subscribes.where(:user_id => self.assignee_id_was).first.destroy unless self.assignee_id_was.blank?
      if self.assignee.notifier.issue_assign && !self.subscribes.exists?(:user_id => self.assignee_id)
        self.subscribes.create(:user_id => self.assignee_id)
      end
    end
  end
end
