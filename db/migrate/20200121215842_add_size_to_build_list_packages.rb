class AddSizeToBuildListPackages < ActiveRecord::Migration[8.1]
  def change
    add_column :build_list_packages, :size, :bigint, default: 0
  end
end
