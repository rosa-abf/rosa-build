class AddLastPublishedCommitHashToBuildList < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :last_published_commit_hash, :string
  end
end
