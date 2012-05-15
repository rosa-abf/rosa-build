class RenameIsRpmToIsPackageInProjects < ActiveRecord::Migration
  def up
    rename_column :projects, :is_rpm, :is_package
  end

  def down
    rename_column :projects, :is_package, :is_rpm
  end
end
