class AddAliasFromToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :alias_from_id, :integer
    add_index :projects, :alias_from_id
  end
end
