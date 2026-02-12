class AddCategoryIdAndDescriptionToProjects < ActiveRecord::Migration[8.1]
  def self.up
    change_table :projects do |t|
      t.references :category
      t.text :description
    end
    add_index :projects, :category_id, if_not_exists: true
  end

  def self.down
    remove_column :projects, :description
    remove_column :projects, :category_id
  end
end
