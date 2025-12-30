class AddLevelToBuildLists < ActiveRecord::Migration
  def change
    add_column :build_lists, :level, :integer, default: 0
    add_column :build_lists, :first_in_chain, :boolean, default: false
  end
end
