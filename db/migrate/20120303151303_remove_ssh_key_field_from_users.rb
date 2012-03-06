class RemoveSshKeyFieldFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :ssh_key
  end

  def down
    add_column :users, :ssh_key, :text
  end
end
