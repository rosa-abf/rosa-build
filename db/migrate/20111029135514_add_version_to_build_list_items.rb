class AddVersionToBuildListItems < ActiveRecord::Migration[8.1]
  def self.up
    add_column :build_list_items, :version, :string
  end

  def self.down
    remove_column :build_list_items, :version
  end
end
