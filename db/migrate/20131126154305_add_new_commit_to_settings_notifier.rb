class AddNewCommitToSettingsNotifier < ActiveRecord::Migration
  def change
    add_column :settings_notifiers, :new_commit, :boolean, :default => false
  end
end
