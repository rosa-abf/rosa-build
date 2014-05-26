class AddUseExtraTestsToBuildListsAndMassBuilds < ActiveRecord::Migration
  def up
    add_column :mass_builds, :use_extra_tests, :boolean, default: false, null: false
    # Make existing build_lists 'false', but default to 'true' in the future.
    add_column :build_lists, :use_extra_tests, :boolean, default: false, null: false
    change_column :build_lists, :use_extra_tests, :boolean, default: true, null: false
  end

  def down
    remove_column :mass_builds, :use_extra_tests
    remove_column :build_lists, :use_extra_tests
  end
end
