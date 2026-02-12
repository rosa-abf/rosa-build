class AddIsRpmToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :is_rpm, :boolean, default: true
  end
end
