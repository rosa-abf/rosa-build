class AddResultsToBuildList < ActiveRecord::Migration
  def change
    add_column :build_lists, :results, :text
    add_column :build_lists, :new_core, :boolean
  end
end
