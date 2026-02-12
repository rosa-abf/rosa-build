class RemoveAdvisoryTables < ActiveRecord::Migration[8.1]
  def change
    Advisory.destroy_all
    drop_table :advisories_platforms
    drop_table :advisories_projects
  end
end
