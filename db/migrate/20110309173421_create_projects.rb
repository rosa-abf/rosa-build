class CreateProjects < ActiveRecord::Migration[8.1]
  def self.up
    create_table :projects do |t|
      t.string :name
      t.string :unixname
      t.integer :platform_id

      t.timestamps
    end
  end

  def self.down
    drop_table :projects
  end
end
