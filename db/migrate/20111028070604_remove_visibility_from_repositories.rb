class RemoveVisibilityFromRepositories < ActiveRecord::Migration
  def self.up
    remove_column :repositories, :visibility
  end

  def self.down
    add_column :repositories, :visibility, :string, :default => "open"
  end
end
