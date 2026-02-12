class AddArchitectureDependentToProject < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :architecture_dependent, :boolean, default: false, null: false
  end
end
