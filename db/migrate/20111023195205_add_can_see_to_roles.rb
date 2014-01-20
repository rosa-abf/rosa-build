class AddCanSeeToRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :can_see, :text
  end

  def self.down
    remove_column :roles, :can_see
  end
end
