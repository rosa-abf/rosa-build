class AddCategoryIdAndDescriptionToProjects < ActiveRecord::Migration
  def self.up
    change_table :projects do |t|
      t.references :category
      t.text :description
    end
    add_index :projects, :category_id
  end

  def self.down
    remove_column :projects, :description
    remove_column :projects, :category_id
  end
end
