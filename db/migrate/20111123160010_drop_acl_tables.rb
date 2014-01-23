class DropAclTables < ActiveRecord::Migration
  def self.up
    drop_table :permissions
    drop_table :rights
    drop_table :role_lines
    drop_table :roles

    remove_column :users, :global_role_id
    remove_column :groups, :global_role_id
  end

  def self.down
    create_table :permissions do |t|
      t.integer  "right_id"
      t.integer  "role_id"
      t.timestamps
    end
    create_table :rights do |t|
      t.string   "name",       null: false
      t.string   "controller", null: false
      t.string   "action",     null: false
      t.timestamps
    end
    create_table :role_lines do |t|
      t.integer  "role_id"
      t.integer  "relation_id"
      t.timestamps
    end
    create_table :roles do |t|
      t.string   "name"
      t.text     "can_see"
      t.string   "on",                    default: ""
      t.string   "to",                    default: ""
      t.boolean  "use_default",           default: false
      t.boolean  "use_default_for_owner", default: false
      t.timestamps
    end

    add_column :users, :global_role_id, :integer
    add_column :groups, :global_role_id, :integer
  end
end
