class AddStartedAtAndDurationToBuildLists < ActiveRecord::Migration
  def change
    add_column :build_lists, :started_at, :datetime
    add_column :build_lists, :duration, :integer
  end
end
