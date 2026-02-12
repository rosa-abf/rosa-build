class AddResultsToBuildList < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :results, :text
    add_column :build_lists, :new_core, :boolean
  end
end
