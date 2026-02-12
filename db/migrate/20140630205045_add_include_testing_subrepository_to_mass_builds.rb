class AddIncludeTestingSubrepositoryToMassBuilds < ActiveRecord::Migration[8.1]
  def change
    add_column :mass_builds, :include_testing_subrepository, :boolean, null: false, default: false
  end
end
