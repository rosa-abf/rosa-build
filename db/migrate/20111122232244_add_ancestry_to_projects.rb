class AddAncestryToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :ancestry, :string
  end

  def self.down
    remove_column :projects, :ancestry
  end
end
