class CreateMassBuilds < ActiveRecord::Migration
  def change
    create_table :mass_builds do |t|
      t.integer :platform_id
      t.string :name

      t.timestamps
    end
  end
end
