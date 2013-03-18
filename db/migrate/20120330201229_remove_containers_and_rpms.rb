class RemoveContainersAndRpms < ActiveRecord::Migration
  def up
    drop_table :containers
    drop_table :rpms
  end

  def down
    create_table "containers" do |t|
      t.string   "name",       :null => false
      t.integer  "project_id", :null => false
      t.integer  "owner_id",   :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "rpms" do |t|
      t.string   "name",       :null => false
      t.integer  "arch_id",    :null => false
      t.integer  "project_id", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index "rpms", ["project_id", "arch_id"], :name => "index_rpms_on_project_id_and_arch_id"
    add_index "rpms", ["project_id"], :name => "index_rpms_on_project_id"
  end
end
