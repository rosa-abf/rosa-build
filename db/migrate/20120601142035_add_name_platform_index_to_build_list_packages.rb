class AddNamePlatformIndexToBuildListPackages < ActiveRecord::Migration[8.1]
  def change
    add_index :build_list_packages, [:name,:project_id]
  end
end
