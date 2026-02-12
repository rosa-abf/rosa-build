class AddListToMassBuild < ActiveRecord::Migration[8.1]
  def change
    add_column :mass_builds, :projects_list, :text
    add_column :mass_builds, :missed_projects_count, :integer, default: 0, null: false
    add_column :mass_builds, :missed_projects_list, :text
  end
end
