class AddEpochToBuildListPackage < ActiveRecord::Migration[8.1]
  def change
    add_column :build_list_packages, :epoch, :integer
  end
end
