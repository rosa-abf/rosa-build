class AddAutostartStatusToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :autostart_status,   :integer
    add_column :projects, :default_platforms,  :text
  end
end
