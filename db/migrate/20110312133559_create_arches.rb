class CreateArches < ActiveRecord::Migration
  def self.up
    create_table :arches do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :arches, :name, unique: true
  end

  def self.down
    drop_table :arches
  end
end
