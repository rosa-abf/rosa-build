class AddAncestryToProjects < ActiveRecord::Migration[8.1]
  def self.up
    add_column :projects, :ancestry, :string
  end

  def self.down
    remove_column :projects, :ancestry
  end
end
