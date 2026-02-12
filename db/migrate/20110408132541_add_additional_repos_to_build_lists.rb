class AddAdditionalReposToBuildLists < ActiveRecord::Migration[8.1]
  def self.up
    add_column :build_lists, :additional_repos, :text
  end

  def self.down
    remove_column :build_lists, :additional_repos
  end
end
