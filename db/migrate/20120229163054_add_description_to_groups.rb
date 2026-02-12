class AddDescriptionToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :description, :text
  end
end
