class CreateRepositories < ActiveRecord::Migration
  def self.up
    create_table :repositories do |t|
      t.string :name, null: false
      t.integer :platform_id, null: false

      t.timestamps
    end
  end

  def self.down
    drop_table :repositories
  end
end
