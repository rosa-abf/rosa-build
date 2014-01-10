class AddGroupIdToBuildList < ActiveRecord::Migration
  def change
    add_column :build_lists, :group_id, :integer
  end
end
