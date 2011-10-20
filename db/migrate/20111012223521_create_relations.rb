class CreateRelations < ActiveRecord::Migration
  def self.up
    create_table :relations do |t|
      t.integer :object_id
      t.string :object_type
      t.integer :target_id
      t.string :target_type

      t.timestamps
    end
  end

  def self.down
    drop_table :relations
  end
end
