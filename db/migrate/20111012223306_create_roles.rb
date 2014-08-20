class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.integer :id
      t.string :name

      t.timestamps
    end
  end
end
