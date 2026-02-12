class AddBuildListNotificationsToSettingsNotifier < ActiveRecord::Migration[8.1]
  def change
    add_column :settings_notifiers, :new_build, :boolean, default: true
    add_column :settings_notifiers, :new_associated_build, :boolean, default: true
  end
end
