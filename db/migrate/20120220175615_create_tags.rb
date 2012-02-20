class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name, :null => false
      t.string :color, :null => false
      t.integer :issue_id, :null => false
      t.integer :project_id, :null => false

      t.timestamps
    end

    add_index :tags, :issue_id
    add_index :tags, :project_id
  end
end
