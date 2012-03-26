# -*- encoding : utf-8 -*-
class Issue < ActiveRecord::Base
  STATUSES = ['open', 'closed']

  belongs_to :project
  belongs_to :user
  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
  belongs_to :closer, :class_name => 'User', :foreign_key => 'closed_by'

  has_many :comments, :as => :commentable, :dependent => :destroy #, :finder_sql => proc { "comments.commentable_id = '#{self.id}' AND comments.commentable_type = '#{self.class.name}'"}
  has_many :subscribes, :as => :subscribeable, :dependent => :destroy #, :finder_sql => proc { "subscribes.subscribeable_id = '#{self.id}' AND subscribes.subscribeable_type = '#{self.class.name}'"}
  has_many :labels, :through => :labelings, :uniq => true
  has_many :labelings

  validates :title, :body, :project_id, :presence => true

  #attr_readonly :serial_id

  after_create :set_serial_id
  after_create :subscribe_users
  after_update :subscribe_issue_assigned_user

  attr_accessible :labelings_attributes, :title, :body, :user_id
  accepts_nested_attributes_for :labelings, :allow_destroy => true

  scope :opened, where(:status => 'open', :closed_by => nil, :closed_at => nil)
  scope :closed, where(:status => 'closed').where("closed_by is not null and closed_at is not null")

  def assign_uname
    user.uname if user
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
    self.closed_at = Time.now
    self.closer = closed_by
    self.status = 'closed'
  end

  def set_open
    self.closed_at = self.closed_by = nil
    self.status = 'open'
  end

  def collect_recipient_ids
    recipients = self.project.relations.by_role('admin').where(:object_type => 'User').map { |rel| rel.read_attribute(:object_id) }
    recipients = recipients | [self.user_id] if self.user_id
    recipients = recipients | [self.project.owner_id] if self.project.owner_type == 'User'

    recipients
  end

  protected

  def set_serial_id
    self.serial_id = self.project.issues.count
    self.save!
  end

  def subscribe_users
    recipients = collect_recipient_ids
    recipients.each do |recipient_id|
      if User.find(recipient_id).notifier.new_comment && !self.subscribes.exists?(:user_id => recipient_id)
        ss = self.subscribes.create(:user_id => recipient_id)
      end
    end
  end

  def subscribe_issue_assigned_user
    if self.user_id && self.user_id_changed?
      self.subscribes.where(:user_id => self.user_id_was).first.destroy unless self.user_id_was.blank?
      if self.user.notifier.issue_assign && !self.subscribes.exists?(:user_id => self.user_id)
        self.subscribes.create(:user_id => self.user_id)
      end
    end
  end

end
