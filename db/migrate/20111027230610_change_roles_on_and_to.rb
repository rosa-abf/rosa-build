class ChangeRolesOnAndTo < ActiveRecord::Migration
  def self.up
    change_column :roles, :on, :string, default: ''
    change_column :roles, :to, :string, default: ''
  end

  def self.down
  end
end
