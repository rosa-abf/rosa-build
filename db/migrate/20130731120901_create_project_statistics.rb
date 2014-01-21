class CreateProjectStatistics < ActiveRecord::Migration
  def change
    create_table :project_statistics do |t|
      t.integer :average_build_time,  null: false, default: 0
      t.integer :build_count,         null: false, default: 0
      t.integer :arch_id,             null: false
      t.integer :project_id,          null: false

      t.timestamps
    end
    add_index :project_statistics, [:project_id, :arch_id], unique: true
  end
end
