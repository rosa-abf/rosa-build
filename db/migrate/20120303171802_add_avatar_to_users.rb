class AddAvatarToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users do |t|
#      t.has_attached_file :avatar
      t.attachment
    end
  end

  def self.down
    drop_attached_file :users, :avatar
  end
end
