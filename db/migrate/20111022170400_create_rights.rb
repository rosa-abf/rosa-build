class CreateRights < ActiveRecord::Migration
  def self.up
    create_table :rights do |t|
      t.string :name, null: false
      t.string :controller, null: false
      t.string :action, null: false

      t.timestamps
    end
  end

  def self.down
    drop_table :rights
  end
end
