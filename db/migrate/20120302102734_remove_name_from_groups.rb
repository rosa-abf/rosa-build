class RemoveNameFromGroups < ActiveRecord::Migration
  def up
    remove_column :groups, :name
  end

  def down
    add_column :groups, :name, :string
  end
end
