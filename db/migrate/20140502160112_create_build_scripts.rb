class CreateBuildScripts < ActiveRecord::Migration
  def change
    create_table :build_scripts do |t|
      t.integer :project_id,  null: false
      t.string  :treeish,     null: false
      t.string  :commit
      t.string  :sha1
      t.string  :status

      t.timestamps
    end

    add_index :build_scripts, [:project_id, :treeish], unique: true
  end
end
