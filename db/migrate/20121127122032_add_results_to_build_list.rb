class AddResultsToBuildList < ActiveRecord::Migration
  def change
    add_column :build_lists, :results, :text
  end
end
