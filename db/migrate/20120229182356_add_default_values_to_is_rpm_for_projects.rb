class AddDefaultValuesToIsRpmForProjects < ActiveRecord::Migration[8.1]
  def change
    Project.update_all(is_rpm: true)
  end
end
