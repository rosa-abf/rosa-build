class AddRolesToRelations < ActiveRecord::Migration
  def self.up
    add_column :relations, :role, :string
    add_column :users, :role, :string
  end

  def self.down
    remove_column :relations, :role
    remove_column :users, :role
  end
end
