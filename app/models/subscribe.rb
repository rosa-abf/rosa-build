class Subscribe < ActiveRecord::Base
  belongs_to :subscribeable, :polymorphic => true
  belongs_to :user

  def self.subscribe_users(project)
    recipients = Subscribe.collect_recipient_ids(project)
    recipients.each do |recipient_id|
      ss = project.commit_comments_subscribes.build(:user_id => recipient_id)
      ss.save!
    end
  end

  def self.collect_recipient_ids(project)
    recipients = project.relations.by_role('admin').where(:object_type => 'User').map { |rel| rel.read_attribute(:object_id) }
#    recipients = recipients | [commentable.user_id] if commentable.user_id
#    recipients = recipients | [commentable.project.owner_id] if commentable.project.owner_type == 'User'

    # filter by notification settings
    recipients = recipients.select do |recipient|
      User.find(recipient).notifier.new_issue && User.find(recipient).notifier.can_notify
    end

    recipients
  end

end
