class AddDataToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :data, :text
  end
end
