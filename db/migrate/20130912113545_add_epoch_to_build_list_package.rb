class AddEpochToBuildListPackage < ActiveRecord::Migration
  def change
    add_column :build_list_packages, :epoch, :integer
  end
end
