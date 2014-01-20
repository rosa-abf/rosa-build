class AddGlobalRoleToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :global_role_id, :integer
  end

  def self.down
    remove_column :groups, :global_role_id
  end
end
