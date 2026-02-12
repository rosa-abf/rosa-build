class AddDefaultFalseToAutoPublishOfMassBuilds < ActiveRecord::Migration[8.1]
  def change
    change_column :mass_builds, :auto_publish, :boolean, default: false, null: false
  end
end
