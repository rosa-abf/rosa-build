class CreateBuildListItems < ActiveRecord::Migration
  def self.up
    create_table :build_list_items, force: true do |t|
      t.string :name
      t.integer :level
      t.integer :status

      t.integer :build_list_id

      t.timestamps
    end

    add_index :build_list_items, :build_list_id
  end

  def self.down
    remove_index :build_list_items, :build_list_id

    drop_table :build_list_items
  end
end
