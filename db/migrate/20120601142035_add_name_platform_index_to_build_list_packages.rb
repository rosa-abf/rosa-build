class AddNamePlatformIndexToBuildListPackages < ActiveRecord::Migration
  def change
    add_index :build_list_packages, [:name,:project_id]
  end
end
