class AddGroupIdToBuildList < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :group_id, :integer
  end
end
