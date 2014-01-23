class AddContainerStatusToBuildList < ActiveRecord::Migration
  class BuildList < ActiveRecord::Base
    WAITING_FOR_RESPONSE = 4000
  end

  def up
    add_column    :build_lists, :container_status, :integer
    remove_column :build_lists, :container_path
    BuildList.where(container_status: nil).update_all(container_status: BuildList::WAITING_FOR_RESPONSE)
  end

  def down
    remove_column :build_lists, :container_status
    add_column    :build_lists, :container_path, :string
  end
end
