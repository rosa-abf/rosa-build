class AddContainerStatusToBuildList < ActiveRecord::Migration
  def up
    add_column    :build_lists, :container_status, :integer
    remove_column :build_lists, :container_path
  end

  def down
    remove_column :build_lists, :container_status
    add_column    :build_lists, :container_path, :string
  end
end
