class AddSoundNotificationsToUser < ActiveRecord::Migration
  def change
    add_column :users, :sound_notifications, :boolean, :default => true
  end
end
