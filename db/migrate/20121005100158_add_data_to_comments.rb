class AddDataToComments < ActiveRecord::Migration
  def change
    add_column :comments, :data, :text
  end
end
