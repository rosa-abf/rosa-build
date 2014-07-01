class AddAutoCreateContainerToMassBuilds < ActiveRecord::Migration
  def change
    add_column :mass_builds, :auto_create_container, :boolean, default: false, null: false
  end
end
