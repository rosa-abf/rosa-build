class AddAutomaticToComments < ActiveRecord::Migration
  def change
    add_column :comments, :automatic, :boolean, default: false

    add_index :comments, :commentable_type
    add_index :comments, :automatic
    add_index :comments, :commentable_id
  end
end
