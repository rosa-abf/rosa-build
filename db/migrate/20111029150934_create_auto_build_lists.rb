class CreateAutoBuildLists < ActiveRecord::Migration
  def self.up
    create_table :auto_build_lists do |t|
      t.integer :project_id
      t.integer :arch_id
      t.integer :pl_id
      t.integer :bpl_id
      t.timestamps
    end
  end

  def self.down
    drop_table :auto_build_lists
  end
end
