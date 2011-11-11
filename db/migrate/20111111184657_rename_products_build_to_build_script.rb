class RenameProductsBuildToBuildScript < ActiveRecord::Migration
  def self.up
    rename_column :products, :build, :build_script
  end

  def self.down
    rename_column :products, :build_script, :build
  end
end
