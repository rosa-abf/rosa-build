class AddDefaultToRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :use_default, :boolean, default: false
    add_column :roles, :use_default_for_owner, :boolean, default: false
  end

  def self.down
    remove_column :roles, :use_default
    remove_column :roles, :use_default_for_owner
  end
end
