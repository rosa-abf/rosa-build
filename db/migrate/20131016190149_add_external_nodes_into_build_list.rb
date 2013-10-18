class AddExternalNodesIntoBuildList < ActiveRecord::Migration
  def change
    add_column :build_lists, :external_nodes, :string
  end
end
