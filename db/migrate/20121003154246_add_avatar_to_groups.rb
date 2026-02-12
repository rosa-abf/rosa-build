class AddAvatarToGroups < ActiveRecord::Migration[8.1]
  def change
    change_table :groups do |t|
#      t.has_attached_file :avatar
      t.attachment
    end
  end

  def self.down
    drop_attached_file :groups, :avatar
  end
end
