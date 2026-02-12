class CreateHooks < ActiveRecord::Migration[8.1]
  def change
    create_table :hooks do |t|
      t.text :data
      t.integer :project_id
      t.string :name

      t.timestamps
    end
  end
end
