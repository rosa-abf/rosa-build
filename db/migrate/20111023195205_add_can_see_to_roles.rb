class AddCanSeeToRoles < ActiveRecord::Migration[8.1]
  def self.up
    add_column :roles, :can_see, :text
  end

  def self.down
    remove_column :roles, :can_see
  end
end
