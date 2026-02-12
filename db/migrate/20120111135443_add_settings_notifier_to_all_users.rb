class AddSettingsNotifierToAllUsers < ActiveRecord::Migration[8.1]
  def self.up
    User.all.each do |user|
      user.create_notifier
    end
  end

  def self.down
    User.all.each do |user|
      user.notifier.destroy
    end
  end
end
