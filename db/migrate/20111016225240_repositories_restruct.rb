class RepositoriesRestruct < ActiveRecord::Migration
  def self.up
    change_table :repositories do |t|
      t.references :owner, polymorphic: true
      t.string :visibility, default: 'open'
    end
  end

  def self.down
    remove_column :repositories, :visibility
    remove_column :repositories, :owner_id
    remove_column :repositories, :owner_type
  end
end
