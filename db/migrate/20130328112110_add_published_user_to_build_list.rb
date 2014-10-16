class AddPublishedUserToBuildList < ActiveRecord::Migration
  def change
    add_column :build_lists, :publisher_id, :integer, references: nil
  end
end
