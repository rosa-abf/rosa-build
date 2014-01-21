class CreateBuildLists < ActiveRecord::Migration
  def self.up
    create_table :build_lists, force: true do |t|
      t.integer :bs_id
      t.string :container_path
      t.integer :status

      t.string :branch_name
      t.integer :project_id
      t.integer :arch_id

      t.timestamp :notified_at

      t.timestamps
    end

    add_index :build_lists, :bs_id, unique: true
    add_index :build_lists, :project_id
    add_index :build_lists, :arch_id
  end

  def self.down
    remove_index :build_lists, :bs_id
    remove_index :build_lists, :project_id
    remove_index :build_lists, :arch_id

    drop_table :build_lists
  end
end
