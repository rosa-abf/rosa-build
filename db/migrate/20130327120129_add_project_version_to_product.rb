class AddProjectVersionToProduct < ActiveRecord::Migration
  def change
    add_column :products, :project_version, :string
  end
end
