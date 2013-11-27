class AddNewCommitToSettingsNotifier < ActiveRecord::Migration
  def change
    add_column :settings_notifiers, :update_code, :boolean, :default => false
  end
end
