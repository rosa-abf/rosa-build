class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  attr_accessor :project

  validates :body, :user_id, :commentable_id, :commentable_type, :presence => true

  after_create :invoke_helper, :if => "commentable_type == 'Grit::Commit'"
  after_create :subscribe_on_reply
  after_create {|comment| Subscribe.new_comment_notification(comment)}

  def helper
    class_eval "def commentable; project.git_repository.commit('#{commentable_id}'); end" if commentable_type == 'Grit::Commit'
  end

  def own_comment?(user)
    user_id == user.id
  end

  protected

  def subscribe_on_reply
    self.commentable.subscribes.create(:user_id => self.user_id) if self.commentable_type == 'Issue' && !self.commentable.subscribes.exists?(:user_id => self.user_id)
    self.project.commit_comments_subscribes.create(:user_id => self.user_id) if self.commentable_type == 'Grit::Commit' && !self.project.commit_comments_subscribes.exists?(:user_id => self.user_id)
  end

  def invoke_helper
    self.helper
  end

  def subscribe_committer
    committer = User.where(:email => self.commentable.committer.email).first
    if committer && !self.project.commit_comments_subscribes.exists?(:user_id => committer.id) && committer.notifier.new_comment_commit_owner
      self.project.commit_comments_subscribes.create(:user_id => committer.id)
    end
  end
end
