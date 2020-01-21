class AddSizeToBuildListPackages < ActiveRecord::Migration
  def change
    add_column :build_list_packages, :size, :bigint, default: 0
  end
end
