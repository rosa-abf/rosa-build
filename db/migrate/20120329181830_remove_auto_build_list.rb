class RemoveAutoBuildList < ActiveRecord::Migration
  def self.up
    drop_table :auto_build_lists
  end

  def self.down
    create_table :auto_build_lists, force: true do |t|
      t.integer  "project_id"
      t.integer  "arch_id"
      t.integer  "pl_id"
      t.integer  "bpl_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
