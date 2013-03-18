class AddOnAndToToRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :on, :string
    add_column :roles, :to, :string
  end

  def self.down
    remove_column :roles, :on
    remove_column :roles, :to
  end
end
