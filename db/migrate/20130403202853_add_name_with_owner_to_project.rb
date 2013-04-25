class AddNameWithOwnerToProject < ActiveRecord::Migration
  def up
    add_column :projects, :owner_uname, :string

    execute <<-SQL
      UPDATE projects SET owner_uname = owners.uname
        FROM users as owners
        WHERE projects.owner_type = 'User' AND projects.owner_id = owners.id
    SQL

    execute <<-SQL
      UPDATE projects SET owner_uname = owners.uname
        FROM groups as owners
        WHERE projects.owner_type = 'Group' AND projects.owner_id = owners.id
    SQL
    change_column :projects, :owner_uname, :string, :null => false
  end

  def down
    remove_column :projects, :owner_uname
  end
end
