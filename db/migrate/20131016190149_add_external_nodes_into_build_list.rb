class AddExternalNodesIntoBuildList < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :external_nodes, :string
  end
end
