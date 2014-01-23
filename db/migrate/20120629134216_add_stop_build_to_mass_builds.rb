class AddStopBuildToMassBuilds < ActiveRecord::Migration
  def change
    add_column :mass_builds, :stop_build, :boolean, null: false, default: false
  end
end
