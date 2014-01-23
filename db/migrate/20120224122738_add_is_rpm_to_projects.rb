class AddIsRpmToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :is_rpm, :boolean, default: true
  end
end
