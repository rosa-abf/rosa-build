# -*- encoding : utf-8 -*-
class Issue < ActiveRecord::Base
  STATUSES = ['open', 'closed']

  belongs_to :project
  belongs_to :user
  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'

  has_many :comments, :as => :commentable, :dependent => :destroy #, :finder_sql => proc { "comments.commentable_id = '#{self.id}' AND comments.commentable_type = '#{self.class.name}'"}
  has_many :subscribes, :as => :subscribeable, :dependent => :destroy #, :finder_sql => proc { "subscribes.subscribeable_id = '#{self.id}' AND subscribes.subscribeable_type = '#{self.class.name}'"}
  has_many :tags, :dependent => :destroy

  validates :title, :body, :project_id, :presence => true

  #attr_readonly :serial_id

  after_create :set_serial_id
  after_create :subscribe_users
  after_create :deliver_new_issue_notification
  after_create :deliver_issue_assign_notification
  after_update :deliver_issue_assign_notification
  after_update :subscribe_issue_assigned_user

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

  protected

  def set_serial_id
    self.serial_id = self.project.issues.count
    self.save!
  end

  def deliver_new_issue_notification
    recipients = collect_recipient_ids
    recipients.each do |recipient_id|
      recipient = User.find(recipient_id)
      UserMailer.delay.new_issue_notification(self, recipient) if User.find(recipient).notifier.can_notify && User.find(recipient).notifier.new_issue
    end
  end

  def deliver_issue_assign_notification
    UserMailer.delay.issue_assign_notification(self, self.user) if self.user_id_was != self.user_id && self.user.notifier.issue_assign && self.user.notifier.can_notify
  end

  def subscribe_users
    recipients = collect_recipient_ids
    recipients.each do |recipient_id|
      ss = self.subscribes.build(:user_id => recipient_id)
      ss.save!
    end
  end

  def collect_recipient_ids
    recipients = self.project.relations.by_role('admin').where(:object_type => 'User').map { |rel| rel.read_attribute(:object_id) }
    recipients = recipients | [self.user_id] if self.user_id
    recipients = recipients | [self.project.owner_id] if self.project.owner_type == 'User'

    # filter by notification settings
    recipients = recipients.select do |recipient|
      User.find(recipient).notifier.new_issue && User.find(recipient).notifier.can_notify
    end

    recipients
  end

  def subscribe_issue_assigned_user
    if self.user_id_was != self.user_id
      self.subscribes.where(:user_id => self.user_id_was).first.destroy unless self.user_id_was.blank?
      if self.user.notifier.issue_assign && !self.subscribes.exists?(:user_id => self.user_id)
        self.subscribes.create(:user_id => self.user_id)
      end
    end
  end
end
