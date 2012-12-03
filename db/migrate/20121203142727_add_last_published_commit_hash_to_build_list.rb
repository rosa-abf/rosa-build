class AddLastPublishedCommitHashToBuildList < ActiveRecord::Migration
  def change
    add_column :build_lists, :last_published_commit_hash, :string
  end
end
