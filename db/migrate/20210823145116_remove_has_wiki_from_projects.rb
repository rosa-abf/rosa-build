class RemoveHasWikiFromProjects < ActiveRecord::Migration
  def change
    remove_column :projects, :has_wiki, :string
  end
end
