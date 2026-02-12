class RenameProductsBuildToBuildScript < ActiveRecord::Migration[8.1]
  def self.up
    rename_column :products, :build, :build_script
  end

  def self.down
    rename_column :products, :build_script, :build
  end
end
