class ProjectRestruct < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.references :owner, :polymorphic => true
      t.string :visibility, :default => 'open'
    end
  end

  def self.down
    remove_column :projects, :visibility
    remove_column :projects, :owner_id
    remove_column :projects, :owner_type
  end
end
