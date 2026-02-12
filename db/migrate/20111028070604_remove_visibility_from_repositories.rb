class RemoveVisibilityFromRepositories < ActiveRecord::Migration[8.1]
  def self.up
    remove_column :repositories, :visibility
  end

  def self.down
    add_column :repositories, :visibility, :string, default: "open"
  end
end
