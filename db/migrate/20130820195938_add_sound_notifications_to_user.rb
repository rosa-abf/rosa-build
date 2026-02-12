class AddSoundNotificationsToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :sound_notifications, :boolean, default: true
  end
end
