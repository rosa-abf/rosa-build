class CreateRpms < ActiveRecord::Migration
  def self.up
    create_table :rpms do |t|
      t.string :name, null: false
      t.integer :arch_id, null: false
      t.integer :project_id, null: false

      t.timestamps
    end

    add_index :rpms, :project_id
    add_index :rpms, [:project_id, :arch_id]
  end

  def self.down
    drop_table :rpms
  end
end
