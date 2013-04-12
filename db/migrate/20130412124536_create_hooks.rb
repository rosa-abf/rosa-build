class CreateHooks < ActiveRecord::Migration
  def change
    create_table :hooks do |t|
      t.text :data
      t.integer :project_id
      t.integer :type

      t.timestamps
    end
  end
end
