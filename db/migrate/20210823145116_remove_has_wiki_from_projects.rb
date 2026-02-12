class RemoveHasWikiFromProjects < ActiveRecord::Migration[8.1]
  def change
    remove_column :projects, :has_wiki, :string
  end
end
