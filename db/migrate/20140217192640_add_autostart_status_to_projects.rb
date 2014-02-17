class AddAutostartStatusToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :autostart_status,  :integer
    add_column :project_to_repositories, :autostart_options, :hstore#, default: '', null: false
  end
end
