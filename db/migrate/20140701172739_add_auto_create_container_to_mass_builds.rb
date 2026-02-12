class AddAutoCreateContainerToMassBuilds < ActiveRecord::Migration[8.1]
  def change
    add_column :mass_builds, :auto_create_container, :boolean, default: false, null: false
  end
end
