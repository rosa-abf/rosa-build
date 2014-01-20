class CreateContainers < ActiveRecord::Migration
  def self.up
    create_table :containers do |t|
      t.string :name, :null => false
      t.integer :project_id, :null => false
      t.integer :owner_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :containers
  end
end
