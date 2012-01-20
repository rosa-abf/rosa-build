class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  attr_accessor :project

  validates :body, :user_id, :commentable_id, :commentable_type, :presence => true

  after_create :invoke_helper, :if => "commentable_type == 'Grit::Commit'"
  after_create :subscribe_on_reply
  after_create :deliver_new_comment_notification

  def helper
    class_eval "def commentable; project.git_repository.commit('#{commentable_id}'); end" if commentable_type == 'Grit::Commit'
  end

  protected

  def deliver_new_comment_notification
    subscribes = self.commentable.subscribes if self.commentable_type == 'Issue'
    # FIXME (true) for rspec
    subscribes = self.project.commit_comments_subscribes(true) if self.commentable_type == 'Grit::Commit'
    subscribes.each do |subscribe|
      if self.commentable_type == 'Issue' && self.user_id != subscribe.user_id && User.find(subscribe.user).notifier.new_comment_reply && User.find(subscribe.user).notifier.can_notify
        if self.commentable.comments.exists?(:user_id => subscribe.user.id)
          UserMailer.delay.new_comment_reply_notification(self, subscribe.user)
        else
          UserMailer.delay.new_comment_notification(self, subscribe.user)
        end
      elsif self.commentable_type == 'Grit::Commit' && self.user_id != subscribe.user_id && User.find(subscribe.user).notifier.new_comment_commit_repo_owner && User.find(subscribe.user).notifier.can_notify
        if Comment.where(:commentable_type => 'Grit::Commit', :commentable_id => self.commentable.id, :user_id => subscribe.user.id).exists?
          UserMailer.delay.new_comment_reply_notification(self, subscribe.user)
        else
          UserMailer.delay.new_comment_notification(self, subscribe.user)
        end
      end
    end
  end

  def subscribe_on_reply
    self.commentable.subscribes.create(:user_id => self.user_id) if self.commentable_type == 'Issue' && !self.commentable.subscribes.exists?(:user_id => self.user_id)
    self.project.commit_comments_subscribes.create(:user_id => self.user_id) if self.commentable_type == 'Grit::Commit' && !self.project.commit_comments_subscribes.exists?(:user_id => self.user_id)
  end

  def invoke_helper
    self.helper
  end

end
