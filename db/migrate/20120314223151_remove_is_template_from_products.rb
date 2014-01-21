class RemoveIsTemplateFromProducts < ActiveRecord::Migration
  def up
    remove_column :products, :is_template
  end

  def down
    add_column :products, "is_template", :boolean, default: false
  end
end
