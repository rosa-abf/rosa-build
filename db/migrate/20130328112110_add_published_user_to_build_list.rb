class AddPublishedUserToBuildList < ActiveRecord::Migration[8.1]
  def change
    add_column :build_lists, :publisher_id, :integer #, references: nil
  end
end
