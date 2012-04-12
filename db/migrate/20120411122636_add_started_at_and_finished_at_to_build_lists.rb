class AddStartedAtAndFinishedAtToBuildLists < ActiveRecord::Migration
  def change
    add_column :build_lists, :started_at, :datetime
    add_column :build_lists, :finished_at, :datetime
  end
end
