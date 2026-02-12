class AddProjectVersionToProduct < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :project_version, :string
  end
end
