class AddAutoPublishToBuildLists < ActiveRecord::Migration
  def self.up
    add_column :build_lists, :auto_publish, :boolean, :default => true
  end

  def self.down
    remove_column :build_lists, :auto_publish
  end
end
