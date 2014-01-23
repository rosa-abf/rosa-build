class AddArchitectureDependentToProject < ActiveRecord::Migration
  def change
    add_column :projects, :architecture_dependent, :boolean, default: false, null: false
  end
end
