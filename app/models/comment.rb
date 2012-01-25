class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
  attr_accessor :project

  validates :body, :user_id, :commentable_id, :commentable_type, :presence => true

  after_create :invoke_helper, :if => "commentable_type == 'Grit::Commit'"
  after_create :subscribe_users
  after_create {|comment| Subscribe.new_comment_notification(comment)}

  def helper
    class_eval "def commentable; project.git_repository.commit('#{commentable_id}'); end" if commentable_type == 'Grit::Commit'
  end

  def own_comment?(user)
    user_id == user.id
  end

  protected

  def invoke_helper
    self.helper
  end

  def subscribe_users
    if self.commentable.class == Issue
      self.commentable.subscribes.create(:user_id => self.user_id) if !self.commentable.subscribes.exists?(:user_id => self.user_id)
    elsif self.commentable.class == Grit::Commit
      recipients = self.project.relations.by_role('admin').where(:object_type => 'User').map &:object # admins
      recipients << self.user << User.where(:email => self.commentable.committer.email).first # commentor and committer
      recipients << self.project.owner if self.project.owner_type == 'User' # project owner
      recipients.compact.uniq.each {|user| Subscribe.subscribe_user_to_commit(self, user.id)}
    end
  end
end
