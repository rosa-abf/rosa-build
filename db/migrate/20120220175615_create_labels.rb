class CreateLabels < ActiveRecord::Migration[8.1]
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

    add_index :labelings, :issue_id, if_not_exists: true
    add_index :labels, :project_id, if_not_exists: true
  end
end
