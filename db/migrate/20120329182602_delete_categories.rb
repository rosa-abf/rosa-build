class DeleteCategories < ActiveRecord::Migration
  def self.up
    remove_column :projects, :category_id
    drop_table :categories
  end

  def self.down
    create_table :categories, force: true do |t|
      t.string   "name"
      t.string   "ancestry"
      t.integer  "projects_count", default: 0, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_column :projects, :category_id, :integer
  end
end
