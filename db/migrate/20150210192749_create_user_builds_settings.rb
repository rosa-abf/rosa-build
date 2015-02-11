class CreateUserBuildsSettings < ActiveRecord::Migration
  def change
    create_table :user_builds_settings do |t|
      t.integer :user_id,         null: false
      t.text :platforms,          null: false, default: [], array: true
      t.string :external_nodes
    end

    add_index :user_builds_settings, :user_id, unique: true
  end
end
