class AddGlobalRoleToGroups < ActiveRecord::Migration[8.1]
  def self.up
    add_column :groups, :global_role_id, :integer #, references: nil
  end

  def self.down
    remove_column :groups, :global_role_id
  end
end
