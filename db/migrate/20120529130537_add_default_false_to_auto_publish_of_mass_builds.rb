class AddDefaultFalseToAutoPublishOfMassBuilds < ActiveRecord::Migration
  def change
    change_column :mass_builds, :auto_publish, :boolean, default: false, null: false
  end
end
