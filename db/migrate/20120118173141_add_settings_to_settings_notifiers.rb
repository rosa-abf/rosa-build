class AddSettingsToSettingsNotifiers < ActiveRecord::Migration
  def self.up
    add_column :settings_notifiers, :new_comment_commit_owner, :boolean, default: true
    add_column :settings_notifiers, :new_comment_commit_repo_owner, :boolean, default: true
    add_column :settings_notifiers, :new_comment_commit_commentor, :boolean, default: true
  end

  def self.down
    remove_column :settings_notifiers, :new_comment_commit_owner
    remove_column :settings_notifiers, :new_comment_commit_repo_owner
    remove_column :settings_notifiers, :new_comment_commit_commentor
  end
end
