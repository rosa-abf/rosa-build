class RenameIsRpmToIsPackageInProjects < ActiveRecord::Migration
  def up
    rename_column :projects, :is_rpm, :is_package
    change_column :projects, :is_package, :boolean, default: true, null: false
  end

  def down
    rename_column :projects, :is_package, :is_rpm
    change_column :projects, :is_package, :boolean, default: true
  end
end
