class CreateLabels < ActiveRecord::Migration
  def change
    create_table :labels do |t|
      t.string :name, null: false
      t.string :color, null: false
      t.references :project

      t.timestamps
    end

    create_table :labelings do |t|
      t.references :label, null: false
      t.references :issue

      t.timestamps
    end

    add_index :labelings, :issue_id
    add_index :labels, :project_id
  end
end
