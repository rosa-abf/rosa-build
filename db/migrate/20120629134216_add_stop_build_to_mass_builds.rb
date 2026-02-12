class AddStopBuildToMassBuilds < ActiveRecord::Migration[8.1]
  def change
    add_column :mass_builds, :stop_build, :boolean, null: false, default: false
  end
end
