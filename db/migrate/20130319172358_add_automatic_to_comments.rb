class AddAutomaticToComments < ActiveRecord::Migration
  def change
    add_column :comments, :automatic, :boolean, :default => false
  end
end
