class AddIncludeTestingSubrepositoryToMassBuilds < ActiveRecord::Migration
  def change
    add_column :mass_builds, :include_testing_subrepository, :boolean, null: false, default: false
  end
end
