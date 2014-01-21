class AddBuildListNotificationsToSettingsNotifier < ActiveRecord::Migration
  def change
    add_column :settings_notifiers, :new_build, :boolean, default: true
    add_column :settings_notifiers, :new_associated_build, :boolean, default: true
  end
end
