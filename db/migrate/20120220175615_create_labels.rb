class CreateLabels < ActiveRecord::Migration
  def change
    create_table :labels do |t|
      t.string :name, :null => false
      t.string :color, :null => false

      t.timestamps
    end

    create_table :labelings do |t|
      t.references :label, :null => false
      t.references :issue
      t.references :project

      t.timestamps
    end

    add_index :labelings, :issue_id
    add_index :labelings, :project_id
  end
end
