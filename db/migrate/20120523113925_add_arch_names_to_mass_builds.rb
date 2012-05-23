class AddArchNamesToMassBuilds < ActiveRecord::Migration
  def change
    add_column :mass_builds, :arch_names, :string
    add_column :mass_builds, :user_id, :integer
    add_column :mass_builds, :auto_publish, :boolean
  end
end
