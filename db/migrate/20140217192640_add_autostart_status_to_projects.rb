class AddAutostartStatusToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :autostart_status,  :integer
    add_column :project_to_repositories, :autostart_options, :hstore
  end
end
