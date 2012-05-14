class CreateBuildListPackages < ActiveRecord::Migration
  def change
    create_table :build_list_packages do |t|
      t.references :build_list
      t.references :project
      t.references :platform
      t.string :fullname
      t.string :name
      t.string :version
      t.string :release
      t.string :package_type

      t.timestamps
    end
    add_index :build_list_packages, :build_list_id
    add_index :build_list_packages, :project_id
    add_index :build_list_packages, :platform_id
  end
end
