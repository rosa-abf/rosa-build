class AddNewCommitToSettingsNotifier < ActiveRecord::Migration[8.1]
  def change
    add_column :settings_notifiers, :update_code, :boolean, default: false
  end
end
