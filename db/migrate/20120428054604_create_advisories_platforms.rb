class CreateAdvisoriesPlatforms < ActiveRecord::Migration
  def up
    create_table :advisories_platforms, id: false do |t|
      t.integer :advisory_id
      t.integer :platform_id
    end
    add_index :advisories_platforms, :advisory_id
    add_index :advisories_platforms, :platform_id
    add_index :advisories_platforms, [:advisory_id, :platform_id], name: :advisory_platform_index, unique: true
  end

  def down
    remove_index :advisories_platforms, column: :advisory_id
    remove_index :advisories_platforms, column: :platform_id
    remove_index :advisories_platforms, name: :advisory_platform_index
    drop_table   :advisories_platforms
  end
end
