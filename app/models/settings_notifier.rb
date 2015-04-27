class SettingsNotifier < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true

  # attr_accessible :can_notify,
  #                 :update_code,
  #                 :new_comment_commit_owner,
  #                 :new_comment_commit_repo_owner,
  #                 :new_comment_commit_commentor,
  #                 :new_comment,
  #                 :new_comment_reply,
  #                 :new_issue,
  #                 :issue_assign,
  #                 :new_build,
  #                 :new_associated_build

end
