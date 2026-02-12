class AddCommitHashToBuildLists < ActiveRecord::Migration[8.1]
  def self.up
    add_column :build_lists, :commit_hash, :string
  end

  def self.down
    remove_column :build_lists, :commit_hash
  end
end
