class RemoveRepositoriesOwner < ActiveRecord::Migration[8.1]
  def self.up
    remove_column :repositories, :owner_id
    remove_column :repositories, :owner_type
    Relation.delete_all #(target_type: 'Repository')
  end

  def self.down
    add_column :repositories, :owner_id, :integer
    add_column :repositories, :owner_type, :string
  end
end
